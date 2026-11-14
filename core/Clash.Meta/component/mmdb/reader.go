package mmdb

import (
	"fmt"
	"net"
	"os"
	"strings"

	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/log"
	"github.com/oschwald/maxminddb-golang"
)

type geoip2Country struct {
	Country struct {
		IsoCode string `maxminddb:"iso_code"`
	} `maxminddb:"country"`
}

type IPReader struct {
	*maxminddb.Reader
	databaseType
}

type ASNReader struct {
	*maxminddb.Reader
}

// CityReader reads a city-level MMDB database (DB-IP Free City Lite in
// production). The embedded reader memory-maps the file, so lookups only
// touch the pages on the search path; the database is never loaded into
// memory wholesale.
type CityReader struct {
	*maxminddb.Reader
}

type cityNamesHolder struct {
	IsoCode string            `maxminddb:"iso_code"`
	Names   map[string]string `maxminddb:"names"`
}

// cityRecord mirrors the GeoIP2-City-shaped record layout shared by
// DBIP-City-Lite and GeoLite2-City databases.
type cityRecord struct {
	Continent struct {
		Code  string            `maxminddb:"code"`
		Names map[string]string `maxminddb:"names"`
	} `maxminddb:"continent"`
	Country          cityNamesHolder `maxminddb:"country"`
	RegisteredCountry cityNamesHolder `maxminddb:"registered_country"`
	Subdivisions     []struct {
		IsoCode string            `maxminddb:"iso_code"`
		Names   map[string]string `maxminddb:"names"`
	} `maxminddb:"subdivisions"`
	City struct {
		Names map[string]string `maxminddb:"names"`
	} `maxminddb:"city"`
}

// CityInfo is the result of a city database lookup. Empty fields mean
// the database has no data for them (e.g. a country-only record).
type CityInfo struct {
	CountryCode   string
	Country       string
	Province      string
	City          string
	ContinentCode string
}

func pickCityName(names map[string]string) string {
	if name := names["en"]; name != "" {
		return name
	}
	for _, name := range names {
		if name != "" {
			return name
		}
	}
	return ""
}

// GeoInfo is the combined local resolution of an IP address across the
// city, country and ASN databases.
type GeoInfo struct {
	CountryCode   string
	Country       string
	Province      string
	City          string
	ASN           string
	ASName        string
	ContinentCode string
	// HasCityDb reports whether the on-demand city database is present;
	// without it the result degrades to country/ASN level.
	HasCityDb bool
}

// LookupGeo resolves ipAddress from the local databases only: the city
// database (country/region/city, when downloaded), the country MMDB as
// country-code fallback, and the ASN database. Nothing is prefetched
// or cached; the lookups run on demand against memory-mapped files.
func LookupGeo(ipAddress net.IP) GeoInfo {
	var info GeoInfo
	if reader := CityInstance(); reader != nil {
		info.HasCityDb = true
		city := reader.LookupCity(ipAddress)
		info.CountryCode = city.CountryCode
		info.Country = city.Country
		info.Province = city.Province
		info.City = city.City
		info.ContinentCode = city.ContinentCode
	}
	// The bundled country/ASN accessors abort the process when their
	// file is missing, so only consult them when the file is actually
	// there; a geo lookup must degrade, never take the process down.
	if info.CountryCode == "" {
		if _, err := os.Stat(C.Path.MMDB()); err == nil {
			if codes := IPInstance().LookupCode(ipAddress); len(codes) > 0 {
				info.CountryCode = strings.ToUpper(codes[0])
			}
		}
	}
	if _, err := os.Stat(C.Path.ASN()); err == nil {
		if asn, name := ASNInstance().LookupASN(ipAddress); asn != "" && asn != "0" {
			info.ASN = "AS" + asn
			info.ASName = name
		}
	}
	return info
}

// LookupCity resolves ip against the city database. It is safe for
// concurrent use and only runs when the UI asks for a lookup.
func (r CityReader) LookupCity(ipAddress net.IP) CityInfo {
	cityMu.RLock()
	defer cityMu.RUnlock()
	var record cityRecord
	_ = r.Lookup(ipAddress, &record)
	country := record.Country
	if country.IsoCode == "" && len(country.Names) == 0 {
		country = record.RegisteredCountry
	}
	info := CityInfo{
		CountryCode:   country.IsoCode,
		Country:       pickCityName(country.Names),
		ContinentCode: record.Continent.Code,
		City:          pickCityName(record.City.Names),
	}
	if len(record.Subdivisions) > 0 {
		info.Province = pickCityName(record.Subdivisions[0].Names)
	}
	return info
}

type GeoLite2 struct {
	AutonomousSystemNumber       uint32 `maxminddb:"autonomous_system_number"`
	AutonomousSystemOrganization string `maxminddb:"autonomous_system_organization"`
}

type IPInfo struct {
	ASN  string `maxminddb:"asn"`
	Name string `maxminddb:"name"`
}

func (r IPReader) LookupCode(ipAddress net.IP) []string {
	switch r.databaseType {
	case typeMaxmind:
		var country geoip2Country
		_ = r.Lookup(ipAddress, &country)
		if country.Country.IsoCode == "" {
			return []string{}
		}
		return []string{strings.ToLower(country.Country.IsoCode)}

	case typeSing:
		var code string
		_ = r.Lookup(ipAddress, &code)
		if code == "" {
			return []string{}
		}
		return []string{code}

	case typeMetaV0:
		var record any
		_ = r.Lookup(ipAddress, &record)
		switch record := record.(type) {
		case string:
			return []string{record}
		case []any: // lookup returned type of slice is []any
			result := make([]string, 0, len(record))
			for _, item := range record {
				result = append(result, item.(string))
			}
			return result
		}
		return []string{}

	default:
		panic(fmt.Sprint("unknown geoip database type:", r.databaseType))
	}
}

func (r ASNReader) LookupASN(ip net.IP) (string, string) {
	switch r.Metadata.DatabaseType {
	case "GeoLite2-ASN", "DBIP-ASN-Lite (compat=GeoLite2-ASN)":
		var result GeoLite2
		_ = r.Lookup(ip, &result)
		return fmt.Sprint(result.AutonomousSystemNumber), result.AutonomousSystemOrganization
	case "ipinfo generic_asn_free.mmdb":
		var result IPInfo
		_ = r.Lookup(ip, &result)
		return result.ASN[2:], result.Name
	default:
		log.Warnln("Unsupported ASN type: %s", r.Metadata.DatabaseType)
	}
	return "", ""
}

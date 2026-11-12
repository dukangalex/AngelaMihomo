package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/metacubex/mihomo/component/mmdb"
	"github.com/metacubex/mihomo/constant"
)

// installGeoFixtures points the core home at a temp dir seeded with the
// tiny generated MMDB fixtures and resets the cached readers so they
// reopen from there.
func installGeoFixtures(t *testing.T, withCity bool) string {
	t.Helper()
	previousHome := constant.Path.HomeDir()
	home := t.TempDir()
	constant.SetHomeDir(home)
	copyFixture := func(src, dst string) {
		data, err := os.ReadFile(filepath.Join("testdata", src))
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(home, dst), data, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	copyFixture("geo_country_test.mmdb", "geoip.metadb")
	copyFixture("geo_asn_test.mmdb", "ASN.mmdb")
	if withCity {
		copyFixture("city_test.mmdb", "City.mmdb")
	}
	mmdb.ReloadIP()
	mmdb.ReloadASN()
	mmdb.ReloadCity()
	t.Cleanup(func() {
		mmdb.ReloadIP()
		mmdb.ReloadASN()
		mmdb.ReloadCity()
		constant.SetHomeDir(previousHome)
	})
	return home
}

func queryIpGeo(t *testing.T, ip string) ipGeoResult {
	t.Helper()
	var result ipGeoResult
	if err := json.Unmarshal([]byte(handleQueryIpGeo(ip)), &result); err != nil {
		t.Fatalf("handleQueryIpGeo(%q) returned invalid JSON: %v", ip, err)
	}
	return result
}

func TestQueryIpGeoWithCityDb(t *testing.T) {
	installGeoFixtures(t, true)
	result := queryIpGeo(t, "1.2.3.4")
	if !result.HasCityDb {
		t.Fatal("hasCityDb = false, want true")
	}
	if result.CountryCode != "US" || result.Country != "United States" {
		t.Errorf("country = %q/%q, want US/United States", result.CountryCode, result.Country)
	}
	if result.Province != "Colorado" {
		t.Errorf("province = %q, want Colorado", result.Province)
	}
	if result.City != "Boulder (Downtown)" {
		t.Errorf("city = %q, want Boulder (Downtown)", result.City)
	}
	if result.ASN != "AS64512" || result.ASName != "TEST-ORG" {
		t.Errorf("asn = %q/%q, want AS64512/TEST-ORG", result.ASN, result.ASName)
	}
	if result.ContinentCode != "NA" {
		t.Errorf("continentCode = %q, want NA", result.ContinentCode)
	}
}

func TestQueryIpGeoWithoutCityDbDegrades(t *testing.T) {
	installGeoFixtures(t, false)
	result := queryIpGeo(t, "1.2.3.4")
	if result.HasCityDb {
		t.Fatal("hasCityDb = true, want false when the city database is absent")
	}
	if result.City != "" || result.Province != "" {
		t.Errorf("city/province = %q/%q, want both empty without city database", result.City, result.Province)
	}
	// Country code and ASN still resolve from their local databases.
	if result.CountryCode != "US" {
		t.Errorf("countryCode = %q, want US from the country MMDB fallback", result.CountryCode)
	}
	if result.ASN != "AS64512" {
		t.Errorf("asn = %q, want AS64512", result.ASN)
	}
}

func TestQueryIpGeoInvalidIP(t *testing.T) {
	installGeoFixtures(t, true)
	result := queryIpGeo(t, "not-an-ip")
	if result.IP != "not-an-ip" || result.CountryCode != "" || result.HasCityDb {
		t.Errorf("invalid ip result = %+v, want bare echo of the input", result)
	}
}

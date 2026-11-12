package mmdb

import (
	"sync"

	mihomoOnce "github.com/metacubex/mihomo/common/once"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/log"

	"github.com/oschwald/maxminddb-golang"
)

type databaseType = uint8

const (
	typeMaxmind databaseType = iota
	typeSing
	typeMetaV0
)

var (
	ipReader  IPReader
	asnReader ASNReader
	ipOnce    sync.Once
	asnOnce   sync.Once

	// cityReader is opened lazily on the first lookup and held as a
	// memory-mapped handle; cityMu guards it against concurrent
	// lookups and reloads.
	cityReader *CityReader
	cityMu     sync.RWMutex
)

func LoadFromBytes(buffer []byte) {
	ipOnce.Do(func() {
		mmdb, err := maxminddb.FromBytes(buffer)
		if err != nil {
			log.Fatalln("Can't load mmdb: %s", err.Error())
		}
		ipReader = IPReader{Reader: mmdb}
		switch mmdb.Metadata.DatabaseType {
		case "sing-geoip":
			ipReader.databaseType = typeSing
		case "Meta-geoip0":
			ipReader.databaseType = typeMetaV0
		default:
			ipReader.databaseType = typeMaxmind
		}
	})
}

func Verify(path string) bool {
	instance, err := maxminddb.Open(path)
	if err == nil {
		instance.Close()
	}
	return err == nil
}

func IPInstance() IPReader {
	ipOnce.Do(func() {
		mmdbPath := C.Path.MMDB()
		log.Infoln("Load MMDB file: %s", mmdbPath)
		mmdb, err := maxminddb.Open(mmdbPath)
		if err != nil {
			log.Fatalln("Can't load MMDB: %s", err.Error())
		}
		ipReader = IPReader{Reader: mmdb}
		switch mmdb.Metadata.DatabaseType {
		case "sing-geoip":
			ipReader.databaseType = typeSing
		case "Meta-geoip0":
			ipReader.databaseType = typeMetaV0
		default:
			ipReader.databaseType = typeMaxmind
		}
	})

	return ipReader
}

func ASNInstance() ASNReader {
	asnOnce.Do(func() {
		ASNPath := C.Path.ASN()
		log.Infoln("Load ASN file: %s", ASNPath)
		asn, err := maxminddb.Open(ASNPath)
		if err != nil {
			log.Fatalln("Can't load ASN: %s", err.Error())
		}
		asnReader = ASNReader{Reader: asn}
	})

	return asnReader
}

func ReloadIP() {
	mihomoOnce.Reset(&ipOnce)
}

func ReloadASN() {
	mihomoOnce.Reset(&asnOnce)
}

// CityInstance returns the city database reader, opening it on first
// use. Unlike IPInstance/ASNInstance it never aborts the process: the
// city database is an optional on-demand download, so a missing or
// invalid file simply yields nil and lookups degrade to country/ASN
// level. The file is opened with maxminddb.Open, which memory-maps it;
// the (large) database is never read into memory as a whole, and no
// background loading or preheating takes place — the handle is created
// only when a lookup is actually requested.
func CityInstance() *CityReader {
	cityMu.RLock()
	reader := cityReader
	cityMu.RUnlock()
	if reader != nil {
		return reader
	}

	cityMu.Lock()
	defer cityMu.Unlock()
	if cityReader != nil {
		return cityReader
	}
	cityPath := C.Path.City()
	mmdb, err := maxminddb.Open(cityPath)
	if err != nil {
		log.Debugln("City database unavailable at %s: %s", cityPath, err.Error())
		return nil
	}
	log.Infoln("Load City MMDB file: %s", cityPath)
	cityReader = &CityReader{Reader: mmdb}
	return cityReader
}

// ReloadCity drops the current city reader (closing its mapping) so the
// next lookup reopens the database file. The updater calls it before
// replacing the file on disk.
func ReloadCity() {
	cityMu.Lock()
	defer cityMu.Unlock()
	if cityReader != nil {
		_ = cityReader.Close()
		cityReader = nil
	}
}

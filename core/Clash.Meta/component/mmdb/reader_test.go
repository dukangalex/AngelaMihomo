package mmdb

import (
	"net"
	"os"
	"path/filepath"
	"testing"

	C "github.com/metacubex/mihomo/constant"

	"github.com/oschwald/maxminddb-golang"
)

func openCityFixture(t *testing.T) CityReader {
	t.Helper()
	reader, err := maxminddb.Open(filepath.Join("testdata", "dbip_city_lite_test.mmdb"))
	if err != nil {
		t.Fatalf("open fixture: %v", err)
	}
	t.Cleanup(func() { _ = reader.Close() })
	if reader.Metadata.DatabaseType != "DBIP-City-Lite" {
		t.Fatalf("fixture database type = %q, want DBIP-City-Lite", reader.Metadata.DatabaseType)
	}
	if reader.Metadata.NodeCount == 0 {
		t.Fatal("fixture node count is zero")
	}
	return CityReader{Reader: reader}
}

func TestCityReaderLookupFullRecord(t *testing.T) {
	reader := openCityFixture(t)
	info := reader.LookupCity(net.ParseIP("1.2.3.4"))
	want := CityInfo{
		CountryCode:   "US",
		Country:       "United States",
		Province:      "Colorado",
		City:          "Boulder (Downtown)",
		ContinentCode: "NA",
	}
	if info != want {
		t.Errorf("LookupCity(1.2.3.4) = %+v, want %+v", info, want)
	}
}

func TestCityReaderLookupCountryOnlyRecord(t *testing.T) {
	reader := openCityFixture(t)
	info := reader.LookupCity(net.ParseIP("5.6.7.8"))
	if info.CountryCode != "AU" || info.Country != "Australia" {
		t.Errorf("LookupCity(5.6.7.8) country = %q/%q, want AU/Australia", info.CountryCode, info.Country)
	}
	if info.Province != "" || info.City != "" {
		t.Errorf("LookupCity(5.6.7.8) province/city = %q/%q, want both empty", info.Province, info.City)
	}
}

func TestCityReaderLookupUnknownIP(t *testing.T) {
	reader := openCityFixture(t)
	info := reader.LookupCity(net.ParseIP("9.9.9.9"))
	if info != (CityInfo{}) {
		t.Errorf("LookupCity(9.9.9.9) = %+v, want zero CityInfo", info)
	}
}

func TestCityInstanceMissingThenPresent(t *testing.T) {
	previousHome := C.Path.HomeDir()
	home := t.TempDir()
	C.SetHomeDir(home)
	t.Cleanup(func() {
		ReloadCity()
		C.SetHomeDir(previousHome)
	})

	if got := CityInstance(); got != nil {
		t.Fatalf("CityInstance() with no database file = %v, want nil", got)
	}

	data, err := os.ReadFile(filepath.Join("testdata", "dbip_city_lite_test.mmdb"))
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(home, C.CityName), data, 0o644); err != nil {
		t.Fatal(err)
	}

	reader := CityInstance()
	if reader == nil {
		t.Fatal("CityInstance() after fixture install = nil, want reader")
	}
	info := reader.LookupCity(net.ParseIP("1.2.3.4"))
	if info.City != "Boulder (Downtown)" {
		t.Errorf("lookup through CityInstance city = %q, want Boulder (Downtown)", info.City)
	}

	ReloadCity()
	if CityInstance() == nil {
		t.Fatal("CityInstance() after ReloadCity = nil, want reopened reader")
	}
}

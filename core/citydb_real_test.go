package main

import (
	"net"
	"os"
	"testing"

	"github.com/metacubex/mihomo/constant"
)

// Real-file cross-check against the production amcity.bin built from
// DB-IP City Lite 2026-11. Skipped when the file is not present.
func TestLookupCityRealFile(t *testing.T) {
	dir := os.Getenv("AMCITY_DIR")
	if dir == "" {
		t.Skip("AMCITY_DIR not set")
	}
	previous := constant.Path.HomeDir()
	constant.SetHomeDir(dir)
	defer constant.SetHomeDir(previous)
	cityMu.Lock()
	cityLoaded = nil
	cityMu.Unlock()
	cases := map[string][3]string{
		"8.8.8.8":              {"US", "California", "Mountain View"},
		"223.5.5.5":            {"CN", "Zhejiang", "Hangzhou"},
		"114.114.114.114":      {"CN", "Shandong", "Jinan"},
		"2001:4860:4860::8888": {"CA", "Quebec", "Montreal"},
	}
	for ip, want := range cases {
		cc, region, city, ok := lookupCity(net.ParseIP(ip))
		if !ok || cc != want[0] || region != want[1] || city != want[2] {
			t.Errorf("%s = %q %q %q ok=%v, want %v", ip, cc, region, city, ok, want)
		}
	}
}

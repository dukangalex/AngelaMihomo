package main

import (
	"encoding/binary"
	"net"
	"os"
	"path/filepath"
	"testing"

	"github.com/metacubex/mihomo/constant"
)

// buildSyntheticCityDB hand-encodes a minimal AMCITY01 file:
// dict: 0=(US, California, Mountain View), 1=(CN, Zhejiang, Hangzhou)
// v4: cells 0x08080800>>8... cells are /24 indices. 8.8.8.0/24 cell =
// 0x080808, run covers 2 cells with tuple 0; cell 0xDF0505 (223.5.5)
// one cell tuple 1. v6: one run at cell 0x2001486048600000>>... top48 of
// 2001:4860:4860:: = 0x200148604860, length 1, tuple 0.
func buildSyntheticCityDB(t *testing.T) []byte {
	t.Helper()
	var buf []byte
	var tmp [binary.MaxVarintLen64]byte
	uv := func(v uint64) {
		n := binary.PutUvarint(tmp[:], v)
		buf = append(buf, tmp[:n]...)
	}
	buf = append(buf, []byte("AMCITY01")...)
	uv(2) // dict count
	uv(2) // v4 runs
	uv(1) // v6 runs
	writeTup := func(cc, region, city string) {
		buf = append(buf, cc...)
		uv(uint64(len(region)))
		buf = append(buf, region...)
		uv(uint64(len(city)))
		buf = append(buf, city...)
	}
	writeTup("US", "California", "Mountain View")
	writeTup("CN", "Zhejiang", "Hangzhou")
	// v4 runs: (delta, len, tid); first run delta from 0
	uv(0x080808)
	uv(2)
	uv(0)
	uv(0xDF0505 - (0x080808 + 2))
	uv(1)
	uv(1)
	// v4 index: every 1024 runs -> just the first
	uv(1)
	uv(0x080808)
	uv(0)
	// v6 runs
	uv(0x200148604860)
	uv(1)
	uv(0)
	uv(1)
	uv(0x200148604860)
	uv(0)
	return buf
}

func TestLookupCitySynthetic(t *testing.T) {
	home := t.TempDir()
	if err := os.WriteFile(filepath.Join(home, cityDBFileName), buildSyntheticCityDB(t), 0o644); err != nil {
		t.Fatal(err)
	}
	previous := constant.Path.HomeDir()
	constant.SetHomeDir(home)
	defer constant.SetHomeDir(previous)
	cityMu.Lock()
	cityLoaded = nil
	cityMu.Unlock()

	cc, region, city, ok := lookupCity(net.ParseIP("8.8.8.8"))
	if !ok || cc != "US" || region != "California" || city != "Mountain View" {
		t.Fatalf("8.8.8.8 = %q %q %q ok=%v", cc, region, city, ok)
	}
	cc, region, city, ok = lookupCity(net.ParseIP("223.5.5.5"))
	if !ok || cc != "CN" || region != "Zhejiang" || city != "Hangzhou" {
		t.Fatalf("223.5.5.5 = %q %q %q ok=%v", cc, region, city, ok)
	}
	cc, _, city, ok = lookupCity(net.ParseIP("2001:4860:4860::8888"))
	if !ok || cc != "US" || city != "Mountain View" {
		t.Fatalf("v6 = %q %q ok=%v", cc, city, ok)
	}
	if _, _, _, ok = lookupCity(net.ParseIP("1.1.1.1")); ok {
		t.Fatalf("1.1.1.1 should not be covered")
	}
}

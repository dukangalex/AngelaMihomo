package main

// AngelaMihomo (chain.26, T194): city-level geolocation served from the
// project's own data repository (dukangalex/angelamihomo-geo). The Dart
// side downloads amcity.bin into the core home directory on first launch
// and keeps it current; this reader picks the file up lazily and reloads
// it whenever it changes. Format specification: FORMAT.md in the data
// repository (grid + run-length encoding, majority tuple per cell).
// All lookups are local; nothing about the queried IP leaves the device.

import (
	"encoding/binary"
	"math/big"
	"net"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/metacubex/mihomo/constant"
)

const cityDBFileName = "amcity.bin"

type cityTuple struct {
	country string
	region  string
	city    string
}

type citySection struct {
	runs []byte
	idx  []cityIndexEntry
}

type cityIndexEntry struct {
	cell   uint64
	offset uint64
}

type cityDB struct {
	dict []cityTuple
	v4   citySection
	v6   citySection
}

var (
	cityMu      sync.Mutex
	cityLoaded  *cityDB
	cityStamp   time.Time
	citySize    int64
	cityChecked time.Time
)

// cityDBPath returns the expected location of the city database inside
// the core home directory, or "" when the home directory is unknown.
func cityDBPath() string {
	home := constant.Path.HomeDir()
	if home == "" {
		return ""
	}
	return filepath.Join(home, cityDBFileName)
}

// loadCityDB returns the parsed city database, reloading it when the
// file on disk has changed. Returns nil when no usable file exists.
// The stat check runs at most once per second; lookups stay cheap.
func loadCityDB() *cityDB {
	cityMu.Lock()
	defer cityMu.Unlock()
	path := cityDBPath()
	if path == "" {
		return nil
	}
	if cityLoaded != nil && time.Since(cityChecked) < time.Second {
		return cityLoaded
	}
	cityChecked = time.Now()
	info, err := os.Stat(path)
	if err != nil {
		cityLoaded = nil
		cityStamp = time.Time{}
		citySize = 0
		return nil
	}
	if cityLoaded != nil && info.ModTime().Equal(cityStamp) && info.Size() == citySize {
		return cityLoaded
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return cityLoaded
	}
	parsed := parseCityDB(data)
	if parsed == nil {
		return cityLoaded
	}
	cityLoaded = parsed
	cityStamp = info.ModTime()
	citySize = info.Size()
	return cityLoaded
}

func parseCityDB(data []byte) *cityDB {
	if len(data) < 8 || string(data[:8]) != "AMCITY01" {
		return nil
	}
	off := 8
	readUV := func() (uint64, bool) {
		v, n := binary.Uvarint(data[off:])
		if n <= 0 {
			return 0, false
		}
		off += n
		return v, true
	}
	dictCount, ok := readUV()
	if !ok {
		return nil
	}
	v4Runs, ok := readUV()
	if !ok {
		return nil
	}
	v6Runs, ok := readUV()
	if !ok {
		return nil
	}
	dict := make([]cityTuple, 0, dictCount)
	for i := uint64(0); i < dictCount; i++ {
		if off+2 > len(data) {
			return nil
		}
		cc := string(data[off : off+2])
		off += 2
		rl, ok := readUV()
		if !ok || off+int(rl) > len(data) {
			return nil
		}
		region := string(data[off : off+int(rl)])
		off += int(rl)
		cl, ok := readUV()
		if !ok || off+int(cl) > len(data) {
			return nil
		}
		city := string(data[off : off+int(cl)])
		off += int(cl)
		dict = append(dict, cityTuple{cc, region, city})
	}
	readSection := func(runCount uint64) (citySection, bool) {
		start := off
		pos := off
		runsEnd := off
		for i := uint64(0); i < runCount; i++ {
			for k := 0; k < 3; k++ {
				_, n := binary.Uvarint(data[pos:])
				if n <= 0 {
					return citySection{}, false
				}
				pos += n
			}
			runsEnd = pos
		}
		off = pos
		idxCount, ok := readUV()
		if !ok {
			return citySection{}, false
		}
		idx := make([]cityIndexEntry, 0, idxCount)
		for i := uint64(0); i < idxCount; i++ {
			cell, ok := readUV()
			if !ok {
				return citySection{}, false
			}
			offset, ok := readUV()
			if !ok {
				return citySection{}, false
			}
			idx = append(idx, cityIndexEntry{cell, offset})
		}
		return citySection{runs: data[start:runsEnd], idx: idx}, true
	}
	v4, ok := readSection(v4Runs)
	if !ok {
		return nil
	}
	v6, ok := readSection(v6Runs)
	if !ok {
		return nil
	}
	return &cityDB{dict: dict, v4: v4, v6: v6}
}

func (s citySection) lookup(cell uint64) (uint32, bool) {
	if len(s.idx) == 0 {
		return 0, false
	}
	lo, hi := 0, len(s.idx)
	for lo < hi {
		mid := (lo + hi) / 2
		if s.idx[mid].cell <= cell {
			lo = mid + 1
		} else {
			hi = mid
		}
	}
	if lo == 0 {
		return 0, false
	}
	pos := int(s.idx[lo-1].offset)
	cur := s.idx[lo-1].cell
	first := true
	for pos < len(s.runs) {
		delta, n := binary.Uvarint(s.runs[pos:])
		if n <= 0 {
			return 0, false
		}
		pos += n
		var start uint64
		if first {
			// The index entry stores this run's absolute start cell; its
			// stored delta is relative to the previous run outside the
			// block and does not apply here.
			start = cur
			first = false
		} else {
			start = cur + delta
		}
		length, n := binary.Uvarint(s.runs[pos:])
		if n <= 0 {
			return 0, false
		}
		pos += n
		tid, n := binary.Uvarint(s.runs[pos:])
		if n <= 0 {
			return 0, false
		}
		pos += n
		if cell >= start && cell < start+length {
			return uint32(tid), true
		}
		if start > cell {
			return 0, false
		}
		cur = start + length
	}
	return 0, false
}

// lookupCity resolves an IP to (country, region, city) from the local
// city database. ok is false when no database or no covering cell exists.
func lookupCity(ip net.IP) (country, region, city string, ok bool) {
	db := loadCityDB()
	if db == nil {
		return "", "", "", false
	}
	var tid uint32
	if ip4 := ip.To4(); ip4 != nil {
		v := binary.BigEndian.Uint32(ip4)
		tid, ok = db.v4.lookup(uint64(v >> 8))
	} else {
		ip16 := ip.To16()
		if ip16 == nil {
			return "", "", "", false
		}
		cell := new(big.Int).Rsh(new(big.Int).SetBytes(ip16), 80).Uint64()
		tid, ok = db.v6.lookup(cell)
	}
	if !ok || int(tid) >= len(db.dict) {
		return "", "", "", false
	}
	t := db.dict[tid]
	return t.country, t.region, t.city, true
}

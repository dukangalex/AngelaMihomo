//go:build !windows

package main

// Memory-mapping for the city database (T208): the ~30 MB amcity.bin
// stays in file-backed pages the OS can evict under pressure instead
// of occupying Go heap for the whole session. The Dart side replaces
// the file by rename, never in place, so a live mapping always sees a
// complete, immutable snapshot.

import (
	"errors"
	"os"

	"golang.org/x/sys/unix"
)

// acquireCityData maps the file at path read-only. The returned
// release function unmaps it and must be called exactly once when the
// data is no longer used.
func acquireCityData(path string) ([]byte, func(), error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, nil, err
	}
	defer f.Close()
	info, err := f.Stat()
	if err != nil {
		return nil, nil, err
	}
	size := info.Size()
	if size <= 0 {
		return nil, nil, errors.New("city database is empty")
	}
	data, err := unix.Mmap(int(f.Fd()), 0, int(size), unix.PROT_READ, unix.MAP_SHARED)
	if err != nil {
		return nil, nil, err
	}
	return data, func() { _ = unix.Munmap(data) }, nil
}

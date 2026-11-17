//go:build windows

package main

// Windows fallback for the city database backing store (T208): no
// mmap wiring here, the file is read into the heap as before. Desktop
// memory headroom makes this acceptable; the memory-critical target
// platform (Android) uses the mmap path.

import "os"

// acquireCityData reads the whole file at path. The release function
// is nil because the heap copy is garbage-collected with the database.
func acquireCityData(path string) ([]byte, func(), error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, nil, err
	}
	return data, nil, nil
}

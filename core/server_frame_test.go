//go:build !cgo

package main

import (
	"bytes"
	"encoding/binary"
	"strings"
	"testing"
)

// T283: readFrame refuses a frame header claiming more than maxFrameLength
// before allocating for it, and still round-trips ordinary frames.
func TestReadFrameRejectsOversizedFrame(t *testing.T) {
	var header [4]byte
	binary.LittleEndian.PutUint32(header[:], uint32(maxFrameLength)+1)
	if _, err := readFrame(bytes.NewReader(header[:])); err == nil || !strings.Contains(err.Error(), "frame too large") {
		t.Fatalf("oversized frame: err = %v", err)
	}
	payload := []byte(`{"id":"1","method":"getMode"}`)
	var buf bytes.Buffer
	if err := writeFrame(&buf, payload); err != nil {
		t.Fatal(err)
	}
	got, err := readFrame(&buf)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(got, payload) {
		t.Fatalf("round trip = %q, want %q", got, payload)
	}
}

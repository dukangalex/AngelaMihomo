package main

import (
	"os"
	"path/filepath"
	"testing"
)

// T111 B-07: whatever a subscription declares, a config assembled by
// the App must come out with the kernel's store-selected cache
// disabled, so the App's selectedMap is the only selection authority
// applied during assembly.
func TestSetupForcesAppSelectedAuthority(t *testing.T) {
	profile := `
mixed-port: 7890
profile:
  store-selected: true
proxies:
  - {name: A, type: ss, server: a.com, port: 1, cipher: aes-128-gcm, password: x}
  - {name: B, type: ss, server: b.com, port: 1, cipher: aes-128-gcm, password: x}
proxy-groups:
  - name: G
    type: select
    proxies: [A, B]
rules:
  - MATCH,G
`
	path := filepath.Join(t.TempDir(), "p.yaml")
	if err := os.WriteFile(path, []byte(profile), 0o644); err != nil {
		t.Fatal(err)
	}
	prepared, err := prepareSetup(&SetupParams{ProfilePath: path})
	if err != nil {
		t.Fatal(err)
	}
	if prepared.rawCfg.Profile.StoreSelected {
		t.Fatal("raw config still has store-selected enabled after App assembly")
	}
	if prepared.cfg.Profile.StoreSelected {
		t.Fatal("parsed config still has store-selected enabled after App assembly")
	}
}

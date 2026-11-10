package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// T81 batch 4: end-to-end assembly snapshot for the single-spec
// layering (docs/config-spec). One fixture sets values at several
// layers at once; the assertions pin the winner of each chain so any
// reordering of the assembly pipeline fails here:
//   - dns section: the App model (L2) wholly replaces the
//     subscription section (L0).
//   - group url: an explicit editor override (L3) beats the App test
//     url rewrite; groups without an explicit url keep the rewrite.
//   - exclude-filter: editor value (L3) replaces the subscription
//     value, with the App-global node filter unioned in.
// The mode synthesis chain is asserted on the Dart side
// (test/providers/update_params_mode_test.dart and
// test/common/system_explicit_test.dart).

func TestSpecSnapshotDnsTakeover(t *testing.T) {
	raw := parsePatchProfile(t, ""+
		"dns:\n  enable: true\n  nameserver: [10.0.0.1]\n  fallback-filter:\n    geosite: [gfw]\n"+
		"proxies:\n  - {name: A, type: ss, server: a.example.com, port: 1, cipher: aes-128-gcm, password: p}\n"+
		"proxy-groups:\n  - {name: Main, type: select, proxies: [A]}\n"+
		"rules:\n  - MATCH,Main\n")
	params := patchParams(t, `{"dns":{"enable":true,"nameserver":["1.1.1.1"],"fallback-filter":{"geosite":["cn"]}}}`)
	if _, err := applyPatch(raw, params); err != nil {
		t.Fatal(err)
	}
	if got := raw.DNS.NameServer; len(got) != 1 || got[0] != "1.1.1.1" {
		t.Errorf("L2 dns must replace the subscription nameserver: got %v", got)
	}
	if got := raw.DNS.FallbackFilter.GeoSite; len(got) != 1 || got[0] != "cn" {
		t.Errorf("L2 dns must replace the subscription fallback-filter: got %v", got)
	}
}

func TestSpecSnapshotExcludeFilterMerge(t *testing.T) {
	// The group is provider-backed (non-nil use list): the global
	// node-exclusion filter only ever applied to such groups, and the
	// editor merge preserves exactly that scope.
	raw := parsePatchProfile(t, ""+
		"proxy-providers:\n  P: {type: http, url: 'https://example.com/sub', path: ./p.yaml, interval: 3600}\n"+
		"proxy-groups:\n  - {name: Main, type: select, use: [P], exclude-filter: 'sub-filter'}\n"+
		"rules:\n  - MATCH,Main\n")
	params := patchParams(t, `{"group-overrides":{"Main":{"exclude-filter":"editor-filter"}},"node-exclude-filter":"global-node"}`)
	if _, err := applyPatch(raw, params); err != nil {
		t.Fatal(err)
	}
	got := raw.ProxyGroup[0]["exclude-filter"]
	text, _ := got.(string)
	if !strings.Contains(text, "editor-filter") || !strings.Contains(text, "global-node") {
		t.Errorf("editor value must replace sub value and union the global filter: got %q", text)
	}
	if strings.Contains(text, "sub-filter") {
		t.Errorf("subscription exclude-filter must not survive the editor override: got %q", text)
	}
}

func TestSpecSnapshotGroupURLChain(t *testing.T) {
	dir := t.TempDir()
	profile := filepath.Join(dir, "profile.yaml")
	content := "proxies:\n  - {name: A, type: ss, server: a.example.com, port: 1, cipher: aes-128-gcm, password: p}\n" +
		"proxy-groups:\n" +
		"  - {name: Main, type: url-test, proxies: [A], url: 'https://sub.example.com/204', interval: 300}\n" +
		"  - {name: Other, type: url-test, proxies: [A], url: 'https://sub.example.com/other', interval: 300}\n" +
		"rules:\n  - MATCH,Main\n"
	if err := os.WriteFile(profile, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	setup := defaultSetupParams()
	setup.ProfilePath = profile
	setup.OverrideTestUrl = true
	setup.TestURL = "https://app.example.com/test"
	setup.Patch = patchParams(t, `{"group-overrides":{"Main":{"url":"https://editor.example.com/health"}}}`)
	prepared, err := prepareSetup(setup)
	if err != nil {
		t.Fatal(err)
	}
	urls := map[string]string{}
	for _, group := range prepared.rawCfg.ProxyGroup {
		name, _ := group["name"].(string)
		url, _ := group["url"].(string)
		urls[name] = url
	}
	if urls["Main"] != "https://editor.example.com/health" {
		t.Errorf("explicit editor url must win over the App test url: got %q", urls["Main"])
	}
	if urls["Other"] != "https://app.example.com/test" {
		t.Errorf("group without an explicit url keeps the App test url: got %q", urls["Other"])
	}
}

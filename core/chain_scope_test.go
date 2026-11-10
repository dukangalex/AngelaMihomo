package main

import (
	"reflect"
	"testing"

	"github.com/metacubex/mihomo/config"
)

// T85: group options must match the group's traffic attribute in both
// directions. The chain landing is a proxy choice, so the chain patch
// may only inject it into selectors that carry a proxy choice;
// direct-only and action-only selectors never receive it, and the
// chain synthesis never contributes a direct option anywhere.

func TestProxyChoiceIndexShapes(t *testing.T) {
	raw := parsePatchProfile(t, `
proxies:
  - {name: NodeA, type: ss, server: a.example, port: 8388, cipher: aes-128-gcm, password: p}
  - {name: NodeB, type: vless, server: b.example, port: 443, uuid: u}
  - {name: DirectA, type: direct}
  - {name: DirectB, type: direct}
proxy-groups:
  - {name: DirectGroup, type: select, proxies: [DirectA, DirectB]}
  - {name: AdBlock, type: select, proxies: [REJECT, REJECT-DROP, PASS]}
  - {name: ProxyGroup, type: select, proxies: [NodeA, NodeB]}
  - {name: MixedGroup, type: select, proxies: [DirectA, NodeA, DIRECT]}
  - {name: NestedDirect, type: select, proxies: [DirectGroup]}
  - {name: NestedProxy, type: select, proxies: [DirectGroup, ProxyGroup]}
  - {name: ProviderGroup, type: select, use: [subscription]}
  - {name: EmptyGroup, type: select, proxies: []}
  - {name: ProviderNamed, type: select, proxies: [NodeFromProvider]}
  - {name: CycleA, type: select, proxies: [CycleB]}
  - {name: CycleB, type: select, proxies: [CycleA]}
  - {name: AutoGroup, type: url-test, proxies: [NodeA], url: "https://example.com", interval: 300}
  - {name: WrapsAuto, type: select, proxies: [AutoGroup]}
proxy-providers:
  subscription:
    type: http
    url: "https://example.invalid/sub"
    path: ./providers/subscription.yaml
rules:
  - MATCH,ProxyGroup
`)
	idx := newProxyChoiceIndex(raw, raw.ProxyGroup)
	cases := []struct {
		group string
		want  bool
	}{
		{"DirectGroup", false},
		{"AdBlock", false},
		{"ProxyGroup", true},
		{"MixedGroup", true},
		{"NestedDirect", false},
		{"NestedProxy", true},
		{"ProviderGroup", true},
		{"EmptyGroup", false},
		{"ProviderNamed", true},
		{"CycleA", false},
		{"CycleB", false},
		{"WrapsAuto", true},
	}
	for _, tc := range cases {
		group := findGroup(raw.ProxyGroup, tc.group)
		if group == nil {
			t.Fatalf("group %q missing", tc.group)
		}
		if got := idx.carriesProxyChoice(group); got != tc.want {
			t.Errorf("carriesProxyChoice(%s) = %v, want %v", tc.group, got, tc.want)
		}
	}
}

// The user's real-world shape: a subscription whose direct group and
// ad-block group sit next to ordinary proxy selectors. Enabling the
// same-profile (legacy) chain must leave both untouched, keep the
// chain as the main selector's default, and add no DIRECT member
// anywhere.
func TestLegacyChainSkipsNonProxySelectors(t *testing.T) {
	raw := parsePatchProfile(t, `
proxies:
  - {name: NodeA, type: http, server: a.example, port: 80}
  - {name: DirectA, type: direct}
  - {name: DirectB, type: direct}
proxy-providers:
  subscription:
    type: inline
    payload:
      - {name: Entry, type: ss, server: e.example.com, port: 8388, cipher: aes-128-gcm, password: p}
      - {name: Landing, type: ss, server: l.example.com, port: 8388, cipher: aes-128-gcm, password: p}
proxy-groups:
  - {name: Main, type: select, proxies: [NodeA]}
  - {name: DirectGroup, type: select, proxies: [DirectA, DirectB]}
  - {name: AdBlock, type: select, proxies: [REJECT, REJECT-DROP, PASS]}
rules:
  - MATCH,Main
`)
	params := patchParams(t, `{"chain-policy": {"enabled": true, "entry": "Entry", "landing": "Landing"}}`)
	if _, err := applyPatch(raw, params); err != nil {
		t.Fatal(err)
	}
	if got := findGroup(raw.ProxyGroup, "Main")["proxies"]; !reflect.DeepEqual(got, []any{explicitChainGroup, "NodeA"}) {
		t.Fatalf("main selector must default to the chain: %#v", got)
	}
	if got := findGroup(raw.ProxyGroup, "DirectGroup")["proxies"]; !reflect.DeepEqual(got, []any{"DirectA", "DirectB"}) {
		t.Fatalf("direct group must not receive the chain landing: %#v", got)
	}
	if got := findGroup(raw.ProxyGroup, "AdBlock")["proxies"]; !reflect.DeepEqual(got, []any{"REJECT", "REJECT-DROP", "PASS"}) {
		t.Fatalf("action group must not receive the chain landing: %#v", got)
	}
	assertNoDirectIntroduced(t, raw)
	parseChainConfig(t, raw)
}

// The cross-profile chain path applies the same attribute match.
func TestExternalChainSkipsNonProxySelectors(t *testing.T) {
	raw := parsePatchProfile(t, `
proxies:
  - {name: Entry, type: http, server: entry.example, port: 80}
  - {name: Node, type: http, server: node.example, port: 80}
  - {name: DirectA, type: direct}
proxy-groups:
  - {name: Main, type: select, proxies: [Node, Entry]}
  - {name: DirectGroup, type: select, proxies: [DirectA, DIRECT]}
  - {name: AdBlock, type: select, proxies: [REJECT, PASS]}
rules:
  - MATCH,Main
`)
	params := &PatchParams{ChainPolicy: &PatchChainPolicy{
		Enabled: true, Entry: "Entry", EntryKind: "proxy",
		Landing: "[ext] Exit Group", LandingKind: "group",
		ExternalProfile: "other", ExternalTarget: "[ext] Exit Group", ExternalKind: "group",
		ExternalProxies: []map[string]any{{"name": "[ext] Exit", "type": "http", "server": "exit.example", "port": 80}},
		ExternalGroups:  []map[string]any{{"name": "[ext] Exit Group", "type": "select", "proxies": []any{"[ext] Exit"}}},
	}}
	if _, err := applyPatch(raw, params); err != nil {
		t.Fatal(err)
	}
	if got := findGroup(raw.ProxyGroup, "Main")["proxies"]; !reflect.DeepEqual(got, []any{explicitChainGroup, "Node", "Entry"}) {
		t.Fatalf("main selector must default to the chain: %#v", got)
	}
	if got := findGroup(raw.ProxyGroup, "DirectGroup")["proxies"]; !reflect.DeepEqual(got, []any{"DirectA", "DIRECT"}) {
		t.Fatalf("direct group must not receive the chain landing: %#v", got)
	}
	if got := findGroup(raw.ProxyGroup, "AdBlock")["proxies"]; !reflect.DeepEqual(got, []any{"REJECT", "PASS"}) {
		t.Fatalf("action group must not receive the chain landing: %#v", got)
	}
	assertNoDirectIntroduced(t, raw, "DirectGroup")
}

// When the first selector is a direct group, it neither receives the
// chain nor counts as the main selector: the first proxy-carrying
// selector takes the default (prepend) treatment instead.
func TestChainMainSelectorIsFirstProxyCarryingSelector(t *testing.T) {
	raw := parsePatchProfile(t, `
proxies:
  - {name: NodeA, type: http, server: a.example, port: 80}
  - {name: NodeB, type: http, server: b.example, port: 80}
  - {name: DirectA, type: direct}
proxy-providers:
  subscription:
    type: inline
    payload:
      - {name: Entry, type: ss, server: e.example.com, port: 8388, cipher: aes-128-gcm, password: p}
      - {name: Landing, type: ss, server: l.example.com, port: 8388, cipher: aes-128-gcm, password: p}
proxy-groups:
  - {name: DirectGroup, type: select, proxies: [DirectA]}
  - {name: Main, type: select, proxies: [NodeA, NodeB]}
  - {name: Secondary, type: select, proxies: [NodeB]}
rules:
  - MATCH,Main
`)
	params := patchParams(t, `{"chain-policy": {"enabled": true, "entry": "Entry", "landing": "Landing"}}`)
	if _, err := applyPatch(raw, params); err != nil {
		t.Fatal(err)
	}
	if got := findGroup(raw.ProxyGroup, "DirectGroup")["proxies"]; !reflect.DeepEqual(got, []any{"DirectA"}) {
		t.Fatalf("direct group must stay untouched: %#v", got)
	}
	if got := findGroup(raw.ProxyGroup, "Main")["proxies"]; !reflect.DeepEqual(got, []any{explicitChainGroup, "NodeA", "NodeB"}) {
		t.Fatalf("first proxy-carrying selector must default to the chain: %#v", got)
	}
	if got := findGroup(raw.ProxyGroup, "Secondary")["proxies"]; !reflect.DeepEqual(got, []any{"NodeB", explicitChainGroup}) {
		t.Fatalf("later proxy selector keeps the chain as a trailing option: %#v", got)
	}
	parseChainConfig(t, raw)
}

// Degenerate profile with no proxy-carrying selector at all: the
// attribute sweep finds nowhere to expose the chain, so the legacy
// fallback sweep keeps it reachable in the only selector that exists
// instead of leaving a dead chain group behind.
func TestLegacyChainFallsBackWhenNoProxySelectorExists(t *testing.T) {
	raw := parsePatchProfile(t, `
proxies:
  - {name: DirectA, type: direct}
proxy-providers:
  subscription:
    type: inline
    payload:
      - {name: Entry, type: ss, server: e.example.com, port: 8388, cipher: aes-128-gcm, password: p}
      - {name: Landing, type: ss, server: l.example.com, port: 8388, cipher: aes-128-gcm, password: p}
proxy-groups:
  - {name: OnlyDirect, type: select, proxies: [DirectA]}
rules:
  - MATCH,OnlyDirect
`)
	params := patchParams(t, `{"chain-policy": {"enabled": true, "entry": "Entry", "landing": "Landing"}}`)
	if _, err := applyPatch(raw, params); err != nil {
		t.Fatal(err)
	}
	if got := findGroup(raw.ProxyGroup, "OnlyDirect")["proxies"]; !reflect.DeepEqual(got, []any{explicitChainGroup, "DirectA"}) {
		t.Fatalf("fallback must keep the chain reachable: %#v", got)
	}
	parseChainConfig(t, raw)
}

// assertNoDirectIntroduced locks the symmetric half for the chain
// synthesis: the generated chain group itself holds no direct option,
// and no group lists a DIRECT member beyond the groups named in
// allowedDirect (where the source fixture itself put one — that is
// the subscription's own content, not the chain patch's doing).
func assertNoDirectIntroduced(t *testing.T, raw *config.RawConfig, allowedDirect ...string) {
	t.Helper()
	allowed := map[string]bool{}
	for _, name := range allowedDirect {
		allowed[name] = true
	}
	chain := findGroup(raw.ProxyGroup, explicitChainGroup)
	if chain == nil {
		t.Fatalf("generated chain group %q missing", explicitChainGroup)
	}
	for _, group := range raw.ProxyGroup {
		name, _ := group["name"].(string)
		for _, member := range anyStrings(group["proxies"]) {
			if member == "DIRECT" && !allowed[name] {
				t.Errorf("group %q gained a DIRECT option from the chain patch", name)
			}
		}
	}
}

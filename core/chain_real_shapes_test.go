package main

// Real-shape regression cases for the chain patcher, modelled on
// real-world shapes reported on 2026-10-27: the entry is a
// provider-backed url-test group named 自动选择 in the active profile,
// and the exit is a group from another profile imported with the
// overlay rename prefix. Synthetic shapes only (structure and scale,
// no real subscription data).

import (
	"fmt"
	"strings"
	"testing"

	"github.com/metacubex/mihomo/adapter/outboundgroup"
)

func rsExitGroup() ([]map[string]any, []map[string]any) {
	groups := []map[string]any{{
		"name":    "[chain 2] 自动选择",
		"type":    "url-test",
		"proxies": []any{"[chain 2] exit-1", "[chain 2] exit-2"},
		"url":     "http://127.0.0.1:1",
	}}
	proxies := []map[string]any{
		{"name": "[chain 2] exit-1", "type": "http", "server": "127.0.0.1", "port": 1},
		{"name": "[chain 2] exit-2", "type": "http", "server": "127.0.0.1", "port": 1},
	}
	return groups, proxies
}

func rsParams(entry string, groups []map[string]any, proxies []map[string]any) *PatchParams {
	return &PatchParams{ChainPolicy: &PatchChainPolicy{
		Enabled: true, Entry: entry, EntryKind: "group",
		Landing: "[chain 2] 自动选择", LandingKind: "group",
		ExternalProfile: "2", ExternalTarget: "[chain 2] 自动选择",
		ExternalKind: "group", ExternalGroups: groups, ExternalProxies: proxies,
	}}
}

// RS1: Lucas's main shape — provider-backed url-test entry group with a
// filter, manual selector present, external url-test exit group.
func TestChainRealShapeProviderAutoEntryExternalGroupExit(t *testing.T) {
	raw := parsePatchProfile(t, `
proxy-providers:
  sub: {type: inline, payload: [{name: hk-1, type: http, server: 127.0.0.1, port: 1}, {name: hk-2, type: http, server: 127.0.0.1, port: 1}]}
proxy-groups:
  - {name: 自动选择, type: url-test, use: [sub], filter: '^hk', url: 'http://127.0.0.1:1', interval: 300}
  - {name: Main, type: select, proxies: [自动选择, DIRECT]}
rules: ['MATCH,Main']
`)
	groups, proxies := rsExitGroup()
	if _, err := applyPatch(raw, rsParams("自动选择", groups, proxies)); err != nil {
		t.Fatalf("applyPatch: %v", err)
	}
	entry := findGroup(raw.ProxyGroup, "自动选择")
	if entry["empty-fallback"] != "REJECT" {
		t.Fatalf("entry group not hardened: %v", entry["empty-fallback"])
	}
	et, _ := entry["exclude-type"].(string)
	for _, want := range []string{"Direct", "Compatible", "Pass"} {
		if !strings.Contains(et, want) {
			t.Fatalf("entry exclude-type %q missing %s", et, want)
		}
	}
	for _, p := range proxies {
		if p["dialer-proxy"] != "自动选择" {
			t.Fatalf("exit proxy %v dialer-proxy = %v", p["name"], p["dialer-proxy"])
		}
	}
	parseChainConfig(t, raw)
}

// RS2: large inline entry group (120 members) + external single-proxy exit.
func TestChainRealShapeLargeInlineEntryGroup(t *testing.T) {
	var members []string
	var lines []string
	for i := 0; i < 120; i++ {
		name := fmt.Sprintf("node-%03d", i)
		members = append(members, name)
		lines = append(lines, fmt.Sprintf("  - {name: %s, type: http, server: 127.0.0.1, port: 1}", name))
	}
	raw := parsePatchProfile(t, fmt.Sprintf(`
proxies:
%s
proxy-groups:
  - {name: 自动选择, type: url-test, proxies: [%s], url: 'http://127.0.0.1:1', interval: 300}
  - {name: Main, type: select, proxies: [自动选择, DIRECT]}
rules: ['MATCH,Main']
`, strings.Join(lines, "\n"), strings.Join(members, ", ")))
	proxies := []map[string]any{{"name": "[chain 2] exit", "type": "http", "server": "127.0.0.1", "port": 1}}
	params := &PatchParams{ChainPolicy: &PatchChainPolicy{
		Enabled: true, Entry: "自动选择", EntryKind: "group",
		Landing: "[chain 2] exit", LandingKind: "proxy",
		ExternalProfile: "2", ExternalTarget: "[chain 2] exit",
		ExternalKind: "proxy", ExternalProxies: proxies,
	}}
	if _, err := applyPatch(raw, params); err != nil {
		t.Fatalf("applyPatch: %v", err)
	}
	parseChainConfig(t, raw)
}

// RS3 (negative control): entry select group containing DIRECT must fail.
func TestChainRealShapeDirectMemberStillRejected(t *testing.T) {
	raw := parsePatchProfile(t, `
proxies:
  - {name: n1, type: http, server: 127.0.0.1, port: 1}
proxy-groups:
  - {name: 自动选择, type: select, proxies: [n1, DIRECT]}
  - {name: Main, type: select, proxies: [自动选择]}
rules: ['MATCH,Main']
`)
	groups, proxies := rsExitGroup()
	if _, err := applyPatch(raw, rsParams("自动选择", groups, proxies)); err == nil {
		t.Fatal("expected bypass validation error, got nil")
	}
}

// RS4: entry group with include-all-proxies must fail as dynamic.
func TestChainRealShapeIncludeAllStillRejected(t *testing.T) {
	raw := parsePatchProfile(t, `
proxies:
  - {name: n1, type: http, server: 127.0.0.1, port: 1}
proxy-groups:
  - {name: 自动选择, type: url-test, include-all-proxies: true, url: 'http://127.0.0.1:1'}
  - {name: Main, type: select, proxies: [自动选择]}
rules: ['MATCH,Main']
`)
	groups, proxies := rsExitGroup()
	if _, err := applyPatch(raw, rsParams("自动选择", groups, proxies)); err == nil {
		t.Fatal("expected dynamic-include validation error, got nil")
	}
}

// RS5: fallback-type entry group, provider-backed, with exclude-filter.
func TestChainRealShapeFallbackEntryWithExcludeFilter(t *testing.T) {
	raw := parsePatchProfile(t, `
proxy-providers:
  sub: {type: inline, payload: [{name: jp-1, type: http, server: 127.0.0.1, port: 1}]}
proxy-groups:
  - {name: 自动选择, type: fallback, use: [sub], exclude-filter: '^dead', url: 'http://127.0.0.1:1', interval: 300}
  - {name: Main, type: select, proxies: [自动选择, DIRECT]}
rules: ['MATCH,Main']
`)
	groups, proxies := rsExitGroup()
	if _, err := applyPatch(raw, rsParams("自动选择", groups, proxies)); err != nil {
		t.Fatalf("applyPatch: %v", err)
	}
	parseChainConfig(t, raw)
}

// RS6: nested entry — select wrapping a provider url-test child that has
// no exclude-type yet; hardening must reach the child.
func TestChainRealShapeNestedProviderChild(t *testing.T) {
	raw := parsePatchProfile(t, `
proxy-providers:
  sub: {type: inline, payload: [{name: us-1, type: http, server: 127.0.0.1, port: 1}]}
proxy-groups:
  - {name: Inner, type: url-test, use: [sub], url: 'http://127.0.0.1:1', interval: 300}
  - {name: 自动选择, type: select, proxies: [Inner]}
  - {name: Main, type: select, proxies: [自动选择, DIRECT]}
rules: ['MATCH,Main']
`)
	groups, proxies := rsExitGroup()
	if _, err := applyPatch(raw, rsParams("自动选择", groups, proxies)); err != nil {
		t.Fatalf("applyPatch: %v", err)
	}
	if findGroup(raw.ProxyGroup, "Inner")["empty-fallback"] != "REJECT" {
		t.Fatal("nested child group not hardened")
	}
	parseChainConfig(t, raw)
}

// RS7: entry group whose provider expansion is filtered to empty at
// runtime (the dangerous window the reject fallback exists for).
func TestChainRealShapeEmptyMemberGroupWithFilter(t *testing.T) {
	raw := parsePatchProfile(t, `
proxy-providers:
  sub: {type: inline, payload: [{name: hk-1, type: http, server: 127.0.0.1, port: 1}]}
proxy-groups:
  - {name: 自动选择, type: url-test, use: [sub], filter: '^zzz-no-match', url: 'http://127.0.0.1:1'}
  - {name: Main, type: select, proxies: [自动选择, DIRECT]}
rules: ['MATCH,Main']
`)
	groups, proxies := rsExitGroup()
	if _, err := applyPatch(raw, rsParams("自动选择", groups, proxies)); err != nil {
		t.Fatalf("applyPatch: %v", err)
	}
	parseChainConfig(t, raw)
}

// RS8 (negative control): entry group referencing a missing provider.
func TestChainRealShapeMissingProviderStillRejected(t *testing.T) {
	raw := parsePatchProfile(t, `
proxy-groups:
  - {name: 自动选择, type: url-test, use: [ghost], url: 'http://127.0.0.1:1'}
  - {name: Main, type: select, proxies: [自动选择]}
rules: ['MATCH,Main']
`)
	groups, proxies := rsExitGroup()
	if _, err := applyPatch(raw, rsParams("自动选择", groups, proxies)); err == nil {
		t.Fatal("expected unavailable-provider validation error, got nil")
	}
}

// RS4 (T310): two exits supplied — only the first is in effect. Its
// group exit is expanded: the generated chain landing group lists the
// group's nodes directly for the user to pick from, the imported group
// is hidden, and the second exit is not imported at all. Every imported
// node must dial through the entry.
func TestChainMultiExitGroupAndProxy(t *testing.T) {
	raw := parsePatchProfile(t, `
proxies:
  - {name: entry-1, type: http, server: 127.0.0.1, port: 1}
proxy-groups:
  - {name: Main, type: select, proxies: [entry-1, DIRECT]}
rules: ['MATCH,Main']
`)
	groupExit := PatchChainExternal{
		ExternalProfile: "2", ExternalTarget: "⛓222222 自动选择",
		ExternalKind: "group",
		ExternalGroups: []map[string]any{{
			"name":    "⛓222222 自动选择",
			"type":    "url-test",
			"proxies": []any{"⛓222222 exit-1", "⛓222222 exit-2"},
			"url":     "http://127.0.0.1:1",
		}},
		ExternalProxies: []map[string]any{
			{"name": "⛓222222 exit-1", "type": "http", "server": "127.0.0.1", "port": 1},
			{"name": "⛓222222 exit-2", "type": "http", "server": "127.0.0.1", "port": 1},
		},
	}
	proxyExit := PatchChainExternal{
		ExternalProfile: "3", ExternalTarget: "⛓333333 solo",
		ExternalKind: "proxy",
		ExternalProxies: []map[string]any{
			{"name": "⛓333333 solo", "type": "http", "server": "127.0.0.1", "port": 1},
		},
	}
	params := &PatchParams{ChainPolicy: &PatchChainPolicy{
		Enabled: true, Entry: "entry-1", EntryKind: "proxy",
		Landing: "⛓222222 自动选择", LandingKind: "group",
		ExternalTargets: []PatchChainExternal{groupExit, proxyExit},
	}}
	if _, err := applyPatch(raw, params); err != nil {
		t.Fatalf("applyPatch: %v", err)
	}
	landing := findGroup(raw.ProxyGroup, "链式落地")
	if landing == nil {
		t.Fatalf("chain landing group missing")
	}
	if landing["type"] != "select" {
		t.Fatalf("chain landing type = %v, want select", landing["type"])
	}
	members := anyStrings(landing["proxies"])
	want := []string{"链式落地-自动选择", "⛓222222 exit-1", "⛓222222 exit-2"}
	if len(members) != len(want) {
		t.Fatalf("chain landing members = %v, want %v", members, want)
	}
	for i, name := range want {
		if members[i] != name {
			t.Fatalf("chain landing members = %v, want %v", members, want)
		}
	}
	auto := findGroup(raw.ProxyGroup, "链式落地-自动选择")
	if auto == nil || auto["type"] != "url-test" {
		t.Fatalf("paired auto-select group missing or wrong type: %v", auto)
	}
	if got := anyStrings(auto["proxies"]); len(got) != 2 {
		t.Fatalf("auto-select members = %v, want both landing nodes", got)
	}
	imported := findGroup(raw.ProxyGroup, "⛓222222 自动选择")
	if imported == nil || imported["hidden"] != true {
		t.Fatalf("imported exit group must stay but be hidden: %v", imported)
	}
	for _, proxy := range raw.Proxy {
		if proxy["name"] == "⛓333333 solo" {
			t.Fatalf("second exit must not be imported under T310")
		}
	}
	for _, name := range []string{"⛓222222 exit-1", "⛓222222 exit-2"} {
		proxy := findProxy(t, raw.Proxy, name)
		if proxy == nil {
			t.Fatalf("imported proxy %q missing", name)
		}
		if proxy["dialer-proxy"] != "entry-1" {
			t.Fatalf("proxy %q dialer-proxy = %v", name, proxy["dialer-proxy"])
		}
	}
	main := findGroup(raw.ProxyGroup, "Main")
	if got := anyStrings(main["proxies"]); len(got) == 0 || got[0] != "链式落地" {
		t.Fatalf("main selector not leading with chain landing: %v", got)
	}
	parseChainConfig(t, raw)
}

// RS9 (T319): a provider-supplied group exit (use, no static members)
// cannot be enumerated at patch time. The landing group and its
// paired auto subgroup inherit the exit group's source keys, so the
// kernel enumerates the provider nodes into both at runtime —
// automatic and manual in the one landing group, like the region
// groups, instead of the imported group sitting there as the sole
// member. The imported group is hidden and the provider nodes still
// dial through the entry.
func TestChainProviderSuppliedGroupExit(t *testing.T) {
	raw := parsePatchProfile(t, `
proxies:
  - {name: entry-1, type: http, server: 127.0.0.1, port: 1}
proxy-groups:
  - {name: Main, type: select, proxies: [entry-1, DIRECT]}
rules: ['MATCH,Main']
`)
	params := &PatchParams{ChainPolicy: &PatchChainPolicy{
		Enabled: true, Entry: "entry-1", EntryKind: "proxy",
		Landing: "⛓222222 出口", LandingKind: "group",
		ExternalTargets: []PatchChainExternal{{
			ExternalProfile: "2", ExternalTarget: "⛓222222 出口",
			ExternalKind: "group",
			ExternalGroups: []map[string]any{{
				"name":   "⛓222222 出口",
				"type":   "url-test",
				"use":    []any{"exit-sub"},
				"filter": "exit",
				"url":    "http://127.0.0.1:1",
			}},
			ExternalProviders: map[string]map[string]any{
				"exit-sub": {
					"type": "inline",
					"payload": []any{
						map[string]any{"name": "⛓222222 exit-1", "type": "http", "server": "127.0.0.1", "port": 1},
						map[string]any{"name": "⛓222222 exit-2", "type": "http", "server": "127.0.0.1", "port": 1},
					},
				},
			},
		}},
	}}
	if _, err := applyPatch(raw, params); err != nil {
		t.Fatalf("applyPatch: %v", err)
	}
	landing := findGroup(raw.ProxyGroup, "链式落地")
	if landing == nil {
		t.Fatalf("chain landing group missing")
	}
	if landing["type"] != "select" {
		t.Fatalf("chain landing type = %v, want select", landing["type"])
	}
	members := anyStrings(landing["proxies"])
	if len(members) != 1 || members[0] != "链式落地-自动选择" {
		t.Fatalf("chain landing members = %v, want only the paired auto group statically", members)
	}
	if got := anyStrings(landing["use"]); len(got) != 1 || got[0] != "exit-sub" {
		t.Fatalf("chain landing use = %v, want the exit group's provider source", landing["use"])
	}
	if landing["filter"] != "exit" {
		t.Fatalf("chain landing filter = %v, want the exit group's filter", landing["filter"])
	}
	auto := findGroup(raw.ProxyGroup, "链式落地-自动选择")
	if auto == nil || auto["type"] != "url-test" {
		t.Fatalf("paired auto-select group missing or wrong type: %v", auto)
	}
	if got := anyStrings(auto["use"]); len(got) != 1 || got[0] != "exit-sub" {
		t.Fatalf("auto-select use = %v, want the exit group's provider source", auto["use"])
	}
	if auto["filter"] != "exit" {
		t.Fatalf("auto-select filter = %v, want the exit group's filter", auto["filter"])
	}
	if auto["url"] != "http://127.0.0.1:1" {
		t.Fatalf("auto-select url = %v, want the exit group's url", auto["url"])
	}
	imported := findGroup(raw.ProxyGroup, "⛓222222 出口")
	if imported == nil || imported["hidden"] != true {
		t.Fatalf("imported exit group must stay but be hidden: %v", imported)
	}
	provider := raw.ProxyProvider["exit-sub"]
	if provider == nil {
		t.Fatalf("imported provider missing")
	}
	override, _ := provider["override"].(map[string]any)
	exprs := anyStrings(override["override-expr"])
	found := false
	for _, expr := range exprs {
		if text, ok := expr.(string); ok && strings.Contains(text, `.dialer-proxy = "entry-1"`) {
			found = true
		}
	}
	if !found {
		t.Fatalf("provider nodes do not dial through the entry: %v", exprs)
	}
	main := findGroup(raw.ProxyGroup, "Main")
	if got := anyStrings(main["proxies"]); len(got) == 0 || got[0] != "链式落地" {
		t.Fatalf("main selector not leading with chain landing: %v", got)
	}
	parsed := parseChainConfig(t, raw)
	landingAdapter := parsed.Proxies["链式落地"]
	if landingAdapter == nil {
		t.Fatalf("parsed chain landing group missing")
	}
	runtimeMembers := landingAdapter.Adapter().(outboundgroup.ProxyGroup).Proxies()
	names := map[string]bool{}
	for _, proxy := range runtimeMembers {
		names[proxy.Name()] = true
	}
	for _, want := range []string{"链式落地-自动选择", "⛓222222 exit-1", "⛓222222 exit-2"} {
		if !names[want] {
			t.Fatalf("parsed chain landing runtime members = %v, want %q among them", names, want)
		}
	}
	if len(runtimeMembers) != 3 {
		t.Fatalf("parsed chain landing runtime members = %v, want auto group plus both provider nodes", names)
	}
}

// RS10 (T319): a wrapper group exit whose sole member is itself a
// group expands one level: the member group heads the landing list
// as the automatic entry and its own nodes follow for manual picks —
// no second auto subgroup is synthesised. A provider-supplied child
// instead lends the landing group its source keys.
func TestChainWrapperGroupExitExpandsOneLevel(t *testing.T) {
	t.Run("static child", func(t *testing.T) {
		raw := parsePatchProfile(t, `
proxies:
  - {name: entry-1, type: http, server: 127.0.0.1, port: 1}
proxy-groups:
  - {name: Main, type: select, proxies: [entry-1, DIRECT]}
rules: ['MATCH,Main']
`)
		params := &PatchParams{ChainPolicy: &PatchChainPolicy{
			Enabled: true, Entry: "entry-1", EntryKind: "proxy",
			Landing: "⛓222222 包装", LandingKind: "group",
			ExternalTargets: []PatchChainExternal{{
				ExternalProfile: "2", ExternalTarget: "⛓222222 包装",
				ExternalKind: "group",
				ExternalGroups: []map[string]any{
					{
						"name":    "⛓222222 包装",
						"type":    "select",
						"proxies": []any{"⛓222222 自动选择"},
					},
					{
						"name":    "⛓222222 自动选择",
						"type":    "url-test",
						"proxies": []any{"⛓222222 exit-1", "⛓222222 exit-2"},
						"url":     "http://127.0.0.1:1",
					},
				},
				ExternalProxies: []map[string]any{
					{"name": "⛓222222 exit-1", "type": "http", "server": "127.0.0.1", "port": 1},
					{"name": "⛓222222 exit-2", "type": "http", "server": "127.0.0.1", "port": 1},
				},
			}},
		}}
		if _, err := applyPatch(raw, params); err != nil {
			t.Fatalf("applyPatch: %v", err)
		}
		landing := findGroup(raw.ProxyGroup, "链式落地")
		if landing == nil {
			t.Fatalf("chain landing group missing")
		}
		if landing["type"] != "select" {
			t.Fatalf("chain landing type = %v, want select", landing["type"])
		}
		members := anyStrings(landing["proxies"])
		want := []string{"⛓222222 自动选择", "⛓222222 exit-1", "⛓222222 exit-2"}
		if len(members) != len(want) {
			t.Fatalf("chain landing members = %v, want %v", members, want)
		}
		for i, name := range want {
			if members[i] != name {
				t.Fatalf("chain landing members = %v, want %v", members, want)
			}
		}
		if auto := findGroup(raw.ProxyGroup, "链式落地-自动选择"); auto != nil {
			t.Fatalf("no paired auto group must be synthesised for a wrapped exit: %v", auto)
		}
		wrapper := findGroup(raw.ProxyGroup, "⛓222222 包装")
		if wrapper == nil || wrapper["hidden"] != true {
			t.Fatalf("wrapper group must stay but be hidden: %v", wrapper)
		}
		child := findGroup(raw.ProxyGroup, "⛓222222 自动选择")
		if child == nil || child["hidden"] == true {
			t.Fatalf("child group is the automatic entry and must stay visible: %v", child)
		}
		for _, name := range []string{"⛓222222 exit-1", "⛓222222 exit-2"} {
			proxy := findProxy(t, raw.Proxy, name)
			if proxy == nil {
				t.Fatalf("imported proxy %q missing", name)
			}
			if proxy["dialer-proxy"] != "entry-1" {
				t.Fatalf("proxy %q dialer-proxy = %v", name, proxy["dialer-proxy"])
			}
		}
		main := findGroup(raw.ProxyGroup, "Main")
		if got := anyStrings(main["proxies"]); len(got) == 0 || got[0] != "链式落地" {
			t.Fatalf("main selector not leading with chain landing: %v", got)
		}
		parseChainConfig(t, raw)
	})

	t.Run("provider child", func(t *testing.T) {
		raw := parsePatchProfile(t, `
proxies:
  - {name: entry-1, type: http, server: 127.0.0.1, port: 1}
proxy-groups:
  - {name: Main, type: select, proxies: [entry-1, DIRECT]}
rules: ['MATCH,Main']
`)
		params := &PatchParams{ChainPolicy: &PatchChainPolicy{
			Enabled: true, Entry: "entry-1", EntryKind: "proxy",
			Landing: "⛓222222 包装", LandingKind: "group",
			ExternalTargets: []PatchChainExternal{{
				ExternalProfile: "2", ExternalTarget: "⛓222222 包装",
				ExternalKind: "group",
				ExternalGroups: []map[string]any{
					{
						"name":    "⛓222222 包装",
						"type":    "select",
						"proxies": []any{"⛓222222 自动选择"},
					},
					{
						"name": "⛓222222 自动选择",
						"type": "url-test",
						"use":  []any{"exit-sub"},
						"url":  "http://127.0.0.1:1",
					},
				},
				ExternalProviders: map[string]map[string]any{
					"exit-sub": {
						"type": "inline",
						"payload": []any{
							map[string]any{"name": "⛓222222 exit-1", "type": "http", "server": "127.0.0.1", "port": 1},
							map[string]any{"name": "⛓222222 exit-2", "type": "http", "server": "127.0.0.1", "port": 1},
						},
					},
				},
			}},
		}}
		if _, err := applyPatch(raw, params); err != nil {
			t.Fatalf("applyPatch: %v", err)
		}
		landing := findGroup(raw.ProxyGroup, "链式落地")
		if landing == nil {
			t.Fatalf("chain landing group missing")
		}
		members := anyStrings(landing["proxies"])
		if len(members) != 1 || members[0] != "⛓222222 自动选择" {
			t.Fatalf("chain landing members = %v, want only the child group statically", members)
		}
		if got := anyStrings(landing["use"]); len(got) != 1 || got[0] != "exit-sub" {
			t.Fatalf("chain landing use = %v, want the child group's provider source", landing["use"])
		}
		if auto := findGroup(raw.ProxyGroup, "链式落地-自动选择"); auto != nil {
			t.Fatalf("no paired auto group must be synthesised for a wrapped exit: %v", auto)
		}
		wrapper := findGroup(raw.ProxyGroup, "⛓222222 包装")
		if wrapper == nil || wrapper["hidden"] != true {
			t.Fatalf("wrapper group must stay but be hidden: %v", wrapper)
		}
		main := findGroup(raw.ProxyGroup, "Main")
		if got := anyStrings(main["proxies"]); len(got) == 0 || got[0] != "链式落地" {
			t.Fatalf("main selector not leading with chain landing: %v", got)
		}
		parseChainConfig(t, raw)
	})
}

// RS5 (T310): a sole group exit imported under the landing group's own
// name is converted in place into the select landing group — no extra
// wrapper is generated, all its nodes stay listed for the user to pick
// from, the main selector points straight at it, and every imported
// node still dials through the entry.
func TestChainSoleGroupExitIsLandingGroup(t *testing.T) {
	raw := parsePatchProfile(t, `
proxies:
  - {name: entry-1, type: http, server: 127.0.0.1, port: 1}
proxy-groups:
  - {name: Main, type: select, proxies: [entry-1, DIRECT]}
rules: ['MATCH,Main']
`)
	params := &PatchParams{ChainPolicy: &PatchChainPolicy{
		Enabled: true, Entry: "entry-1", EntryKind: "proxy",
		Landing: "链式落地", LandingKind: "group",
		ExternalTargets: []PatchChainExternal{{
			ExternalProfile: "2", ExternalTarget: "链式落地",
			ExternalKind: "group",
			ExternalGroups: []map[string]any{{
				"name":    "链式落地",
				"type":    "url-test",
				"proxies": []any{"⛓exit-1", "⛓exit-2"},
				"url":     "http://127.0.0.1:1",
			}},
			ExternalProxies: []map[string]any{
				{"name": "⛓exit-1", "type": "http", "server": "127.0.0.1", "port": 1},
				{"name": "⛓exit-2", "type": "http", "server": "127.0.0.1", "port": 1},
			},
		}},
	}}
	if _, err := applyPatch(raw, params); err != nil {
		t.Fatalf("applyPatch: %v", err)
	}
	if len(raw.ProxyGroup) != 3 {
		t.Fatalf("expected exactly Main + landing group + paired auto group, got %d groups", len(raw.ProxyGroup))
	}
	landing := findGroup(raw.ProxyGroup, "链式落地")
	if landing == nil {
		t.Fatalf("landing group missing")
	}
	if landing["type"] != "select" {
		t.Fatalf("landing group type = %v, want select (converted in place)", landing["type"])
	}
	members := anyStrings(landing["proxies"])
	if len(members) != 3 || members[0] != "链式落地-自动选择" {
		t.Fatalf("landing group members = %v, want paired auto group first, then both nodes", members)
	}
	for _, name := range []string{"⛓exit-1", "⛓exit-2"} {
		proxy := findProxy(t, raw.Proxy, name)
		if proxy == nil {
			t.Fatalf("imported proxy %q missing", name)
		}
		if proxy["dialer-proxy"] != "entry-1" {
			t.Fatalf("proxy %q dialer-proxy = %v", name, proxy["dialer-proxy"])
		}
	}
	main := findGroup(raw.ProxyGroup, "Main")
	if got := anyStrings(main["proxies"]); len(got) == 0 || got[0] != "链式落地" {
		t.Fatalf("main selector not leading with chain landing: %v", got)
	}
	parseChainConfig(t, raw)
}

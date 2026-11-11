package main

import (
	"strings"
	"testing"
)

// T87: China-routing invariant for rule mode with China adaptation
// on. China traffic must only ever go DIRECT and non-China traffic
// must end at a proxy choice. The China-direct pair emitted by the
// system-explicit options already lands ahead of every surviving
// profile rule (same-category profile rules are replaced, the rest
// keep their order after the additions); the kernel, however, falls
// back to DIRECT when no rule matches, so the MATCH tail is guarded
// here: a missing MATCH, a MATCH to a builtin action, or a MATCH to
// a group that carries no proxy choice is rewritten to the first
// proxy-carrying group.

const cnInvariantExplicit = `{"system-explicit-rules": [
	"GEOSITE,category-ads-all,REJECT",
	"IP-CIDR,223.5.5.5/32,DIRECT,no-resolve",
	"DOMAIN-SUFFIX,alidns.com,DIRECT",
	"GEOSITE,geolocation-cn,DIRECT",
	"GEOIP,CN,DIRECT,no-resolve",
	"GEOSITE,private,DIRECT",
	"GEOIP,private,DIRECT,no-resolve",
	"IP-CIDR,192.168.0.0/16,DIRECT,no-resolve"
]}`

const cnInvariantProfileHead = `
proxies:
  - {name: NodeA, type: ss, server: a.example, port: 8388, cipher: aes-128-gcm, password: p}
  - {name: DirectA, type: direct}
proxy-groups:
  - {name: MainSelect, type: select, proxies: [NodeA]}
  - {name: DirectGroup, type: select, proxies: [DirectA, DIRECT]}
`

func ruleIndex(rules []string, want string) int {
	for i, rule := range rules {
		if rule == want {
			return i
		}
	}
	return -1
}

func firstMatchTarget(rules []string) (string, bool) {
	for _, rule := range rules {
		parsed := parseRule(rule)
		if parsed.action == "MATCH" {
			return parsed.target, true
		}
	}
	return "", false
}

// The adversarial subscription from the task: early rules try to send
// China traffic to the proxy selector and the tail is MATCH,DIRECT.
// After assembly the China-direct pair must precede every surviving
// China-matching profile rule, the same-category proxy rules must be
// gone, and the tail must point at the proxy selector.
func TestChinaInvariantAdversarialSubscription(t *testing.T) {
	raw := parsePatchProfile(t, cnInvariantProfileHead+`
rules:
  - GEOSITE,geolocation-cn,MainSelect
  - DOMAIN-SUFFIX,baidu.com,MainSelect
  - GEOIP,CN,MainSelect,no-resolve
  - DOMAIN-SUFFIX,example.com,MainSelect
  - MATCH,DIRECT
`)
	if _, err := applyPatch(raw, patchParams(t, cnInvariantExplicit)); err != nil {
		t.Fatal(err)
	}
	rules := raw.Rule
	if got := ruleIndex(rules, "GEOSITE,geolocation-cn,MainSelect"); got != -1 {
		t.Errorf("same-category China proxy rule survived at %d: %v", got, rules)
	}
	if got := ruleIndex(rules, "GEOIP,CN,MainSelect,no-resolve"); got != -1 {
		t.Errorf("same-category China-IP proxy rule survived at %d: %v", got, rules)
	}
	cnSite := ruleIndex(rules, "GEOSITE,geolocation-cn,DIRECT")
	cnIP := ruleIndex(rules, "GEOIP,CN,DIRECT,no-resolve")
	if cnSite == -1 || cnIP == -1 {
		t.Fatalf("China-direct pair missing from assembled rules: %v", rules)
	}
	baidu := ruleIndex(rules, "DOMAIN-SUFFIX,baidu.com,MainSelect")
	if baidu == -1 {
		t.Fatalf("unrelated profile rule should survive: %v", rules)
	}
	if cnSite > baidu || cnIP > baidu {
		t.Errorf("China-direct pair must precede surviving China-matching profile rules: %v", rules)
	}
	target, ok := firstMatchTarget(rules)
	if !ok || target != "MainSelect" {
		t.Errorf("MATCH tail = %q (found %v), want MainSelect: %v", target, ok, rules)
	}
	if got := ruleIndex(rules, "MATCH,DIRECT"); got != -1 {
		t.Errorf("MATCH,DIRECT survived assembly: %v", rules)
	}
}

// A subscription without any MATCH relies on the kernel's DIRECT
// fallback for everything unmatched; the guard appends a proxy tail.
func TestChinaInvariantAppendsMissingMatch(t *testing.T) {
	raw := parsePatchProfile(t, cnInvariantProfileHead+`
rules:
  - DOMAIN-SUFFIX,example.com,MainSelect
`)
	if _, err := applyPatch(raw, patchParams(t, cnInvariantExplicit)); err != nil {
		t.Fatal(err)
	}
	last := raw.Rule[len(raw.Rule)-1]
	if last != "MATCH,MainSelect" {
		t.Errorf("last rule = %q, want appended MATCH,MainSelect: %v", last, raw.Rule)
	}
}

// A subscription whose MATCH already names a proxy-carrying selector
// is authoritative: the tail is kept verbatim.
func TestChinaInvariantKeepsValidMatch(t *testing.T) {
	raw := parsePatchProfile(t, cnInvariantProfileHead+`
rules:
  - DOMAIN-SUFFIX,example.com,MainSelect
  - MATCH,MainSelect
`)
	if _, err := applyPatch(raw, patchParams(t, cnInvariantExplicit)); err != nil {
		t.Fatal(err)
	}
	target, ok := firstMatchTarget(raw.Rule)
	if !ok || target != "MainSelect" {
		t.Errorf("MATCH tail = %q (found %v), want untouched MainSelect: %v", target, ok, raw.Rule)
	}
}

// A MATCH naming a direct-only selector is a direct route wearing a
// group's name; it does not satisfy the invariant.
func TestChinaInvariantRewritesDirectGroupMatch(t *testing.T) {
	raw := parsePatchProfile(t, cnInvariantProfileHead+`
rules:
  - MATCH,DirectGroup
`)
	if _, err := applyPatch(raw, patchParams(t, cnInvariantExplicit)); err != nil {
		t.Fatal(err)
	}
	target, _ := firstMatchTarget(raw.Rule)
	if target != "MainSelect" {
		t.Errorf("MATCH tail = %q, want MainSelect: %v", target, raw.Rule)
	}
}

// A MATCH whose group the user disabled is retargeted to PASS by the
// disabled-group step; PASS at the tail unwraps to the kernel DIRECT
// fallback, so the guard must replace it with an enabled proxy group.
func TestChinaInvariantRewritesDisabledMatchTarget(t *testing.T) {
	raw := parsePatchProfile(t, `
proxies:
  - {name: NodeA, type: ss, server: a.example, port: 8388, cipher: aes-128-gcm, password: p}
proxy-groups:
  - {name: DisabledSelect, type: select, proxies: [NodeA]}
  - {name: BackupAuto, type: url-test, proxies: [NodeA], url: "https://example.com", interval: 300}
rules:
  - MATCH,DisabledSelect
`)
	params := patchParams(t, `{"system-explicit-rules": [
		"GEOSITE,geolocation-cn,DIRECT",
		"GEOIP,CN,DIRECT,no-resolve"
	], "disabled-groups": ["DisabledSelect"]}`)
	if _, err := applyPatch(raw, params); err != nil {
		t.Fatal(err)
	}
	target, ok := firstMatchTarget(raw.Rule)
	if !ok || target != "BackupAuto" {
		t.Errorf("MATCH tail = %q (found %v), want BackupAuto: %v", target, ok, raw.Rule)
	}
}

// Without the China-direct pair the invariant is not in force (China
// adaptation off, or a synthesized global/direct mode): the
// subscription's tail is none of the guard's business.
func TestChinaInvariantNotArmedWithoutChinaPair(t *testing.T) {
	for name, explicit := range map[string]string{
		"interception only": `{"system-explicit-rules": ["GEOSITE,category-ads-all,REJECT"]}`,
		"no explicit rules": `{}`,
		"half pair":         `{"system-explicit-rules": ["GEOSITE,geolocation-cn,DIRECT"]}`,
	} {
		t.Run(name, func(t *testing.T) {
			raw := parsePatchProfile(t, cnInvariantProfileHead+`
rules:
  - MATCH,DIRECT
`)
			if _, err := applyPatch(raw, patchParams(t, explicit)); err != nil {
				t.Fatal(err)
			}
			target, _ := firstMatchTarget(raw.Rule)
			if target != "DIRECT" {
				t.Errorf("MATCH tail = %q, want untouched DIRECT: %v", target, raw.Rule)
			}
		})
	}
}

// Rule strings must stay parseable end to end: the assembled config
// still unmarshals and the guard emits exactly one effective tail.
func TestChinaInvariantSingleEffectiveTail(t *testing.T) {
	raw := parsePatchProfile(t, cnInvariantProfileHead+`
rules:
  - MATCH,DIRECT
  - DOMAIN-SUFFIX,late.example,MainSelect
`)
	if _, err := applyPatch(raw, patchParams(t, cnInvariantExplicit)); err != nil {
		t.Fatal(err)
	}
	matches := 0
	for _, rule := range raw.Rule {
		if strings.HasPrefix(rule, "MATCH,") {
			matches++
			if rule != "MATCH,MainSelect" {
				t.Errorf("unexpected MATCH rule %q in %v", rule, raw.Rule)
			}
		}
	}
	if matches != 1 {
		t.Errorf("got %d MATCH rules, want exactly 1: %v", matches, raw.Rule)
	}
}

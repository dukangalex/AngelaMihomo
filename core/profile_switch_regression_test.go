package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/metacubex/mihomo/component/geodata/router"
	"github.com/metacubex/mihomo/constant"
	"google.golang.org/protobuf/proto"
)

// T146 regression: the profile-switch verdict is exactly the error of
// setupConfig's prepareSetup stage (parseProfile -> applyPatch ->
// config.ParseRawConfig); errors from the later ApplyConfig stage never
// reach the switch flow. The test therefore asserts at that seam and
// stays out of the live-process surface (listeners, applied providers),
// whose vendored background goroutines are not race-clean under -race. External (non-converter) subscription shapes — HTTP proxy and
// rule providers, url-test/fallback/load-balance groups built on `use`,
// emoji node names, China-split rules — must apply successfully through
// the full app patch pipeline, and converter-shaped profiles must not
// regress. The import-side half of T146 (an unvalidated auto-update must
// not replace a working profile with core-rejected content) is covered
// by TestImportProfileUnvalidatedUpdateKeepsWorkingFile.

const switchProxyPayload = `proxies:
  - {name: "🇭🇰 香港 01", type: ss, server: 127.0.0.1, port: 8388, cipher: aes-128-gcm, password: x}
  - {name: "🇯🇵 日本 01", type: ss, server: 127.0.0.1, port: 8389, cipher: aes-128-gcm, password: x}
`

const switchDomainPayload = `payload:
  - '.example.com'
  - '.example.org'
`

const switchIpcidrPayload = `payload:
  - '203.0.113.0/24'
`

const switchClassicalPayload = `payload:
  - 'DOMAIN-SUFFIX,example.net'
  - 'IP-CIDR,198.51.100.0/24,no-resolve'
`

func switchConverterProfile() string {
	return `mixed-port: 7890
mode: rule
dns:
  enable: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver: [https://dns.alidns.com/dns-query, 223.5.5.5]
  fallback: [https://dns.google/dns-query]
proxies:
  - {name: "🇭🇰 香港 01", type: ss, server: 127.0.0.1, port: 8388, cipher: aes-128-gcm, password: x}
  - {name: "🇯🇵 日本 01", type: ss, server: 127.0.0.1, port: 8389, cipher: aes-128-gcm, password: x}
  - {name: "🇺🇸 美国 01", type: trojan, server: 127.0.0.1, port: 443, password: x, sni: example.com}
proxy-groups:
  - {name: "🚀 节点选择", type: select, proxies: ["♻️ 自动选择", "🇭🇰 香港 01", "🇯🇵 日本 01", "🇺🇸 美国 01", DIRECT]}
  - {name: "♻️ 自动选择", type: url-test, proxies: ["🇭🇰 香港 01", "🇯🇵 日本 01", "🇺🇸 美国 01"], url: "http://www.gstatic.com/generate_204", interval: 300}
rules:
  - GEOIP,CN,DIRECT
  - GEOSITE,CN,DIRECT
  - MATCH,🚀 节点选择
`
}

func switchExternalProfile(base string) string {
	return fmt.Sprintf(`mixed-port: 7890
mode: rule
dns:
  enable: true
  ipv6: false
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver: [https://dns.alidns.com/dns-query, https://doh.pub/dns-query]
  fallback: [https://dns.google/dns-query, https://cloudflare-dns.com/dns-query]
  fallback-filter: {geoip: true, geoip-code: CN}
  nameserver-policy:
    "+.example.com": [223.5.5.5]
proxies:
  - {name: "🏠 家宽 01", type: ss, server: 127.0.0.1, port: 8390, cipher: aes-128-gcm, password: x}
proxy-providers:
  airport-a:
    type: http
    url: "%s/proxies-a"
    path: ./providers/airport-a.yaml
    interval: 86400
    health-check: {enable: true, url: "http://www.gstatic.com/generate_204", interval: 300}
  airport-b:
    type: http
    url: "%s/proxies-b"
    path: ./providers/airport-b.yaml
    interval: 86400
    health-check: {enable: true, url: "http://www.gstatic.com/generate_204", interval: 300}
rule-providers:
  reject-domain:
    type: http
    behavior: domain
    format: yaml
    url: "%s/rp-domain"
    path: ./providers/reject-domain.yaml
    interval: 86400
  direct-domain:
    type: http
    behavior: domain
    format: yaml
    url: "%s/rp-domain2"
    path: ./providers/direct-domain.yaml
    interval: 86400
  proxy-domain:
    type: http
    behavior: domain
    format: yaml
    url: "%s/rp-domain3"
    path: ./providers/proxy-domain.yaml
    interval: 86400
  cn-ip:
    type: http
    behavior: ipcidr
    format: yaml
    url: "%s/rp-ipcidr"
    path: ./providers/cn-ip.yaml
    interval: 86400
  classical-set:
    type: http
    behavior: classical
    format: yaml
    url: "%s/rp-classical"
    path: ./providers/classical-set.yaml
    interval: 86400
proxy-groups:
  - {name: "🚀 手动切换", type: select, proxies: ["♻️ 自动选择", "🔰 故障转移", "🏠 家宽 01", DIRECT], use: [airport-a, airport-b]}
  - {name: "♻️ 自动选择", type: url-test, use: [airport-a, airport-b], url: "http://www.gstatic.com/generate_204", interval: 300, tolerance: 50}
  - {name: "🔰 故障转移", type: fallback, use: [airport-a], url: "http://www.gstatic.com/generate_204", interval: 300}
  - {name: "⚖️ 负载均衡", type: load-balance, use: [airport-b], url: "http://www.gstatic.com/generate_204", interval: 300}
rules:
  - RULE-SET,reject-domain,REJECT
  - RULE-SET,direct-domain,DIRECT
  - RULE-SET,cn-ip,DIRECT,no-resolve
  - RULE-SET,classical-set,🚀 手动切换
  - RULE-SET,proxy-domain,🚀 手动切换
  - GEOIP,CN,DIRECT
  - MATCH,🚀 手动切换
`, base, base, base, base, base, base, base)
}

// switchExplicitRulesAllOn mirrors SystemExplicitOptions.buildRuntimeRules
// with every option enabled (rule mode), as buildPatchParams sends it.
func switchExplicitRulesAllOn() []string {
	return []string{
		"AND,((NETWORK,UDP),(DST-PORT,5353)),REJECT",
		"AND,((NETWORK,UDP),(DST-PORT,5355)),REJECT",
		"AND,((NETWORK,UDP),(DST-PORT,1900)),REJECT",
		"GEOSITE,category-ads-all,REJECT",
		"DOMAIN-KEYWORD,stun,REJECT",
		"DOMAIN-KEYWORD,turn,REJECT",
		"DOMAIN-SUFFIX,stun.l.google.com,REJECT",
		"AND,((NETWORK,UDP),(DST-PORT,3478-3480)),REJECT",
		"AND,((NETWORK,UDP),(DST-PORT,5349-5355)),REJECT",
		"AND,((NETWORK,UDP),(DST-PORT,19302-19305)),REJECT",
		"IP-CIDR,223.5.5.5/32,DIRECT,no-resolve",
		"IP-CIDR,119.29.29.29/32,DIRECT,no-resolve",
		"DOMAIN-SUFFIX,alidns.com,DIRECT",
		"DOMAIN-SUFFIX,doh.pub,DIRECT",
		"GEOSITE,geolocation-cn,DIRECT",
		"GEOIP,CN,DIRECT,no-resolve",
		"GEOSITE,private,DIRECT",
		"GEOIP,private,DIRECT,no-resolve",
		"IP-CIDR,10.0.0.0/8,DIRECT,no-resolve",
		"IP-CIDR,172.16.0.0/12,DIRECT,no-resolve",
		"IP-CIDR,192.168.0.0/16,DIRECT,no-resolve",
		"DOMAIN-SUFFIX,local,DIRECT",
		"DOMAIN-SUFFIX,home.arpa,DIRECT",
	}
}

func switchPatchParams(providersPath string) *PatchParams {
	general := map[string]any{
		"mode": "rule", "log-level": "info", "mixed-port": 7890,
		"allow-lan": false, "ipv6": false, "unified-delay": true,
		"tcp-concurrent": true, "find-process-mode": "off",
		"tun": map[string]any{"enable": false},
	}
	generalJSON, _ := json.Marshal(general)
	return &PatchParams{
		General:            generalJSON,
		ProvidersPath:      providersPath,
		SelectGlobal:       true,
		HealthCheckTimeout: defaultHealthCheckTimeout,
	}
}

func TestProfileSwitchExternalShapes(t *testing.T) {
	previousHome := constant.Path.HomeDir()
	defer constant.SetHomeDir(previousHome)

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/yaml")
		switch r.URL.Path {
		case "/proxies-a", "/proxies-b":
			_, _ = w.Write([]byte(switchProxyPayload))
		case "/rp-ipcidr":
			_, _ = w.Write([]byte(switchIpcidrPayload))
		case "/rp-classical":
			_, _ = w.Write([]byte(switchClassicalPayload))
		default:
			_, _ = w.Write([]byte(switchDomainPayload))
		}
	}))
	defer server.Close()

	// Hermetic geo fixtures generated in-test: the real databases under
	// assets/data are gitignored (downloaded at build time), so a clean
	// checkout has nothing to seed from.
	seed := switchTestGeoFixtures(t)

	run := func(name, content string, mutate func(*PatchParams)) {
		home := t.TempDir()
		constant.SetHomeDir(home)
		for n, data := range seed {
			if err := os.WriteFile(filepath.Join(home, n), data, 0o644); err != nil {
				t.Fatal(err)
			}
		}
		path := filepath.Join(home, "profile.yaml")
		if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
			t.Fatal(err)
		}
		patch := switchPatchParams(filepath.Join(home, "providers"))
		if mutate != nil {
			mutate(patch)
		}
		start := time.Now()
		prepared, err := prepareSetup(&SetupParams{
			ProfilePath: path,
			TestURL:     "http://127.0.0.1/",
			Patch:       patch,
		})
		if err != nil {
			t.Errorf("%s: setup verdict failed: %v", name, err)
		} else {
			// Parsing starts provider health-check rounds; join and
			// stop them before the next case (see settleParsedProviders).
			settleParsedProviders(t, prepared.cfg.Providers)
		}
		t.Logf("%s: elapsed=%s err=%v", name, time.Since(start).Round(time.Millisecond), err)
	}

	run("converter", switchConverterProfile(), nil)
	run("external", switchExternalProfile(server.URL), nil)
	run("external-explicit-all-on", switchExternalProfile(server.URL), func(p *PatchParams) {
		p.SystemExplicitRules = switchExplicitRulesAllOn()
		p.PrependRules = []string{
			"AND,((NETWORK,UDP),(DST-PORT,443),(NOT,((OR,((GEOSITE,geolocation-cn),(GEOIP,CN,no-resolve)))))),REJECT",
		}
	})
	run("external-dead-providers", switchExternalProfile("http://127.0.0.1:1"), nil)
}

// switchTestGeoFixtures builds minimal but valid geo databases covering
// the codes the fixtures reference (CN, GEOLOCATION-CN, CATEGORY-ADS-ALL,
// PRIVATE; every IP resolves to CN).
func switchTestGeoFixtures(t *testing.T) map[string][]byte {
	t.Helper()
	site := func(code, domain string) *router.GeoSite {
		return &router.GeoSite{
			CountryCode: code,
			Domain:      []*router.Domain{{Type: router.Domain_Domain, Value: domain}},
		}
	}
	geoSite, err := proto.Marshal(&router.GeoSiteList{Entry: []*router.GeoSite{
		site("CN", "example.cn"),
		site("GEOLOCATION-CN", "example.cn"),
		site("CATEGORY-ADS-ALL", "ads.example.com"),
		site("PRIVATE", "local"),
	}})
	if err != nil {
		t.Fatal(err)
	}
	return map[string][]byte{
		"GeoSite.dat":  geoSite,
		"geoip.metadb": switchTestMMDB(),
	}
}

func mmdbStr(s string) []byte {
	return append([]byte{0x40 | byte(len(s))}, s...)
}

func mmdbU16(v uint16) []byte {
	if v == 0 {
		return []byte{0xa0}
	}
	if v <= 0xff {
		return []byte{0xa1, byte(v)}
	}
	return []byte{0xa2, byte(v >> 8), byte(v)}
}

// switchTestMMDB hand-builds the smallest valid MaxMind DB: one node,
// both branches pointing at a single record {country:{iso_code:"CN"}}.
func switchTestMMDB() []byte {
	record := []byte{0xe1}
	record = append(record, mmdbStr("country")...)
	record = append(record, 0xe1)
	record = append(record, mmdbStr("iso_code")...)
	record = append(record, mmdbStr("CN")...)

	meta := []byte{0xe9} // map, 9 entries
	add := func(key string, value []byte) {
		meta = append(meta, mmdbStr(key)...)
		meta = append(meta, value...)
	}
	add("binary_format_major_version", mmdbU16(2))
	add("binary_format_minor_version", mmdbU16(0))
	// build_epoch: uint64 (extended type 9 -> ext 2), 4-byte value.
	add("build_epoch", []byte{0x04, 0x02, 0x65, 0x53, 0xf1, 0x00})
	add("database_type", mmdbStr("GeoIP2-Country"))
	desc := append([]byte{0xe1}, mmdbStr("en")...)
	desc = append(desc, mmdbStr("Test")...)
	add("description", desc)
	add("ip_version", mmdbU16(4))
	lang := []byte{0x01, 0x04} // array (extended type 11 -> ext 4), 1 item
	lang = append(lang, mmdbStr("en")...)
	add("languages", lang)
	add("node_count", []byte{0xc1, 0x01}) // uint32, 1 byte
	add("record_size", mmdbU16(24))

	out := []byte{0, 0, 17, 0, 0, 17} // tree: 1 node, both records -> data offset 16
	out = append(out, make([]byte, 16)...)
	out = append(out, record...)
	out = append(out, []byte("\xab\xcd\xefMaxMind.com")...)
	out = append(out, meta...)
	return out
}


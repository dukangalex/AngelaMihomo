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

	"github.com/metacubex/mihomo/constant"
)

// T146 regression: the profile-switch verdict is the core setupConfig
// result. External (non-converter) subscription shapes — HTTP proxy and
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

	seed := map[string][]byte{}
	for _, name := range []string{"geoip.metadb", "GeoSite.dat", "ASN.mmdb"} {
		data, err := os.ReadFile(filepath.Join("..", "assets", "data", name))
		if err != nil {
			t.Fatal(err)
		}
		seed[name] = data
	}

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
		_, err := setupConfig(&SetupParams{
			ProfilePath: path,
			TestURL:     "http://127.0.0.1/",
			Patch:       patch,
		})
		if err != nil {
			t.Errorf("%s: setup failed: %v", name, err)
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

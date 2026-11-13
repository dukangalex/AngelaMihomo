package main

import (
	"encoding/json"
	"reflect"
	"strings"
	"testing"

	"github.com/metacubex/mihomo/common/yaml"
	"github.com/metacubex/mihomo/log"
	yamlv3 "go.yaml.in/yaml/v3"
	cp "github.com/metacubex/mihomo/constant/provider"
	"github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/common/utils"
)

func TestPatchYamlShortID(t *testing.T) {
	cases := map[string]string{
		"    short-id: 0123abcd\n":                    "    short-id: \"0123abcd\"\n",
		"    short-id: 1e5\n":                         "    short-id: \"1e5\"\n",
		"    short-id: 12345678 # note\n":             "    short-id: \"12345678\" # note\n",
		"    short-id:   ABCDEF\n":                    "    short-id:   \"ABCDEF\"\n",
		"reality-opts: {public-key: k, short-id: 01}": "reality-opts: {public-key: k, short-id: \"01\"}",
		"{short-id: 01, public-key: k}":               "{short-id: \"01\", public-key: k}",
		"    short-id: \"0123abcd\"\n":                "    short-id: \"0123abcd\"\n",
		"    short-id: '0123abcd'\n":                  "    short-id: '0123abcd'\n",
		"    short-id: xyz\n":                         "    short-id: xyz\n",
		"    short-id: 0123abcdxyz\n":                 "    short-id: 0123abcdxyz\n",
		"    short-id:\n":                             "    short-id:\n",
		"    short-id: 0123abcd":                      "    short-id: \"0123abcd\"",
	}
	for input, want := range cases {
		if got := string(patchYamlShortID([]byte(input))); got != want {
			t.Errorf("patchYamlShortID(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestLogHistoryCarriesTime(t *testing.T) {
	handleClearLogs()
	t.Cleanup(func() { handleClearLogs() })
	recordLogHistory(logEntry{
		Event: log.Event{LogLevel: log.WARNING, Payload: "[DNS] timeout"},
		Time:  1760000000123,
	})
	var items []map[string]any
	if err := json.Unmarshal([]byte(handleGetLogs()), &items); err != nil {
		t.Fatal(err)
	}
	if len(items) != 1 {
		t.Fatalf("len = %d, want 1", len(items))
	}
	want := map[string]any{
		"LogLevel": "warning",
		"Payload":  "[DNS] timeout",
		"time":     float64(1760000000123),
	}
	if !reflect.DeepEqual(items[0], want) {
		t.Errorf("entry = %v, want %v", items[0], want)
	}
}

func TestMarshalYamlNodeKeepingSupplementary(t *testing.T) {
	type entry struct {
		Name  string `yaml:"name"`
		Value string `yaml:"value"`
	}
	entries := []entry{
		{"🇭🇰 香港 01 ⭐", "0123"},
		{"🚀 节点选择", "true"},
		{`literal \U0001F680 text`, "line one\nline two 🚀\n"},
		{"☁️ plain \ue000", "quoted \"🚀\" \\U0001F680"},
	}
	var root yamlv3.Node
	if err := root.Encode(map[string]any{"entries": entries}); err != nil {
		t.Fatal(err)
	}
	out, err := marshalYamlNode(&root)
	if err != nil {
		t.Fatal(err)
	}
	content := string(out)
	for _, shown := range []string{"🇭🇰 香港 01 ⭐", "🚀 节点选择", "line two 🚀"} {
		if !strings.Contains(content, shown) {
			t.Fatalf("%q is escaped in: %s", shown, content)
		}
	}
	var parsed map[string][]entry
	if err := yaml.Unmarshal(out, &parsed); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(parsed["entries"], entries) {
		t.Fatalf("entries changed: %#v", parsed["entries"])
	}
}

func TestResidentRawConfigDropsProxiesAndGroups(t *testing.T) {
	raw, err := parseProfile([]byte(`proxies:
  - {name: a, type: ss, server: 1.1.1.1, port: 1, cipher: aes-128-gcm, password: p}
proxy-groups:
  - {name: g, type: select, proxies: [a]}
proxy-providers:
  inline: {type: inline, payload: [{name: b, type: ss, server: 1.1.1.1, port: 2, cipher: aes-128-gcm, password: p}]}
rule-providers:
  ads: {type: http, behavior: domain, url: https://example.com/ads.mrs, format: mrs}
dns:
  enable: true
  enhanced-mode: fake-ip
rules:
  - GEOSITE,google,g
  - MATCH,g
`), "")
	if err != nil {
		t.Fatal(err)
	}
	resident := residentRawConfig(raw)
	if resident.Proxy != nil || resident.ProxyGroup != nil {
		t.Fatalf("proxies or groups kept: %d %d", len(resident.Proxy), len(resident.ProxyGroup))
	}
	if len(raw.Proxy) != 1 || len(raw.ProxyGroup) != 1 {
		t.Fatalf("source changed: %d %d", len(raw.Proxy), len(raw.ProxyGroup))
	}
	if !resident.DNS.Enable || len(resident.Rule) != 2 || len(resident.RuleProvider) != 1 {
		t.Fatalf("resident lost fields: %+v", resident.DNS.Enable)
	}
	if _, err := marshalInlineProviderContent(resident, "inline"); err != nil {
		t.Fatal(err)
	}
	if residentRawConfig(nil) != nil {
		t.Fatal("nil config should stay nil")
	}
}


// T89 D-08: a URLTest failure observed before the data plane is ready
// must not be reported (it would park a false -1/"Timeout" in the UI
// delay map); every other combination must be reported so genuine
// timeouts still surface once the TUN is up.
func TestShouldReportDelay(t *testing.T) {
	cases := []struct {
		name  string
		delay uint16
		ready bool
		want  bool
	}{
		{"failure before data plane ready is dropped", 0, false, false},
		{"failure after data plane ready is reported", 0, true, true},
		{"success before data plane ready is reported", 120, false, true},
		{"success after data plane ready is reported", 120, true, true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := shouldReportDelay(tc.delay, tc.ready); got != tc.want {
				t.Fatalf(
					"shouldReportDelay(%d, %v) = %v, want %v",
					tc.delay, tc.ready, got, tc.want,
				)
			}
		})
	}
}

// T111 A-12: the post-ready recheck must run exactly the providers
// that have a health-check URL; providers without one have no
// periodic delay state to correct and must not be force-checked
// (a check with no URL would manufacture failures).
type fakeProxyProvider struct {
	url     string
	checked int
}

func (f *fakeProxyProvider) Name() string                { return "fake" }
func (f *fakeProxyProvider) VehicleType() cp.VehicleType { return cp.Inline }
func (f *fakeProxyProvider) Type() cp.ProviderType       { return cp.Proxy }
func (f *fakeProxyProvider) Initial() error              { return nil }
func (f *fakeProxyProvider) Update() error               { return nil }
func (f *fakeProxyProvider) Proxies() []constant.Proxy   { return nil }
func (f *fakeProxyProvider) Count() int                  { return 0 }
func (f *fakeProxyProvider) Touch()                      {}
func (f *fakeProxyProvider) Version() uint32             { return 0 }
func (f *fakeProxyProvider) HealthCheckURL() string      { return f.url }
func (f *fakeProxyProvider) HealthCheck()                { f.checked++ }
func (f *fakeProxyProvider) RegisterHealthCheckTask(
	string,
	utils.IntRanges[uint16],
	string,
	uint,
) {
}

func TestRecheckProviderDelaysOnlyChecksProvidersWithURL(t *testing.T) {
	withURL := &fakeProxyProvider{url: "https://example.com/generate_204"}
	withoutURL := &fakeProxyProvider{}
	recheckProviderDelays(map[string]cp.ProxyProvider{
		"with":    withURL,
		"without": withoutURL,
	})
	if withURL.checked != 1 {
		t.Fatalf("provider with URL checked %d times, want 1", withURL.checked)
	}
	if withoutURL.checked != 0 {
		t.Fatalf("provider without URL checked %d times, want 0", withoutURL.checked)
	}
}

package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/metacubex/mihomo/constant"
)

// T127 reproduction: the core-side setupConfig verdict is the single
// authority on whether a profile applied, but its duration is profile
// dependent. Applying a config synchronously performs the initial fetch
// of every cache-less HTTP provider (hub loadProvider -> Fetcher.Initial
// -> HTTP vehicle read, whose own timeout budget is 20s per fetch), so a
// legitimate, ultimately successful setup can take far longer than the
// 15 seconds the Dart side used to allow before declaring the switch
// failed and rolling back. These tests pin the core-side behavior the
// Dart deadline must respect: slow-but-valid setups succeed, fast setups
// succeed quickly, and genuinely invalid configs still return an error.
//
// The scenario runs in a child process: setupConfig drives the shared
// core through full config applies, and other tests in this package
// leave parsed proxy adapters behind whose finalizer-driven Close calls
// log concurrently (racing the log-level write inside ApplyConfig —
// the pre-existing T124-family latent pattern in the vendored core).
// Isolating the applies keeps this timing evidence free of that noise.

const t127HelperEnv = "T127_SETUP_TIMING_HELPER"

const t127ProviderPayload = `proxies:
  - {name: "P1", type: ss, server: 127.0.0.1, port: 8388, cipher: aes-128-gcm, password: x}
`

func t127ProfileWithProvider(name, url string) string {
	return fmt.Sprintf(`proxy-providers:
  %s:
    type: http
    url: %s
    path: ./providers/%s.yaml
    interval: 86400
    health-check:
      enable: false
proxy-groups:
  - name: G
    type: select
    use: [%s]
rules:
  - MATCH,G
`, name, url, name, name)
}

func t127RunSetup(t *testing.T, dir, file, content string) (time.Duration, error) {
	t.Helper()
	path := filepath.Join(dir, file)
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	start := time.Now()
	_, err := setupConfig(&SetupParams{ProfilePath: path, TestURL: "http://127.0.0.1/"})
	return time.Since(start), err
}

func TestSetupConfigTimingVsAppDeadline(t *testing.T) {
	if os.Getenv(t127HelperEnv) != "1" {
		cmd := exec.Command(
			os.Args[0],
			"-test.run", "^TestSetupConfigTimingVsAppDeadline$",
			"-test.count=1", "-test.v",
		)
		cmd.Env = append(os.Environ(), t127HelperEnv+"=1")
		out, err := cmd.CombinedOutput()
		if err != nil {
			text := string(out)
			if len(text) > 4000 {
				text = text[len(text)-4000:]
			}
			t.Fatalf("setup timing helper failed: %v\n%s", err, text)
		}
		if !strings.Contains(string(out), "--- PASS: TestSetupConfigTimingVsAppDeadline") {
			t.Fatalf("helper did not report PASS:\n%s", out)
		}
		return
	}

	previousHome := constant.Path.HomeDir()
	home := t.TempDir()
	constant.SetHomeDir(home)
	defer constant.SetHomeDir(previousHome)

	delay := time.Duration(0)
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if delay > 0 {
			time.Sleep(delay)
		}
		w.Header().Set("Content-Type", "text/yaml")
		_, _ = w.Write([]byte(t127ProviderPayload))
	}))
	defer server.Close()

	// Fast control: the provider answers immediately, setup must succeed
	// well inside any plausible deadline.
	elapsed, err := t127RunSetup(t, home, "fast.yaml",
		t127ProfileWithProvider("t127fast", server.URL+"/fast"))
	if err != nil {
		t.Fatalf("fast setup failed: %v", err)
	}
	if elapsed > 15*time.Second {
		t.Fatalf("fast setup took %v, want well under 15s", elapsed)
	}

	// Slow case: a single cache-less provider fetch that answers after
	// 18s. The core still applies the config successfully — only after
	// the 15s deadline the app side used to enforce. A switch judged by
	// that deadline is a false failure.
	delay = 18 * time.Second
	elapsed, err = t127RunSetup(t, home, "slow.yaml",
		t127ProfileWithProvider("t127slow", server.URL+"/slow"))
	if err != nil {
		t.Fatalf("slow setup failed: %v", err)
	}
	if elapsed < 15*time.Second {
		t.Fatalf("slow setup took %v, want it to cross the old 15s app deadline", elapsed)
	}
	if elapsed > 45*time.Second {
		t.Fatalf("slow setup took %v, beyond the fetch-bound envelope", elapsed)
	}

	// Genuine failure control: an invalid profile must still surface an
	// error from the core (awaiting the core verdict does not mask real
	// failures), and it must surface promptly.
	delay = 0
	elapsed, err = t127RunSetup(t, home, "bad.yaml", `proxies:
  - {name: X, type: no-such-type, server: 127.0.0.1, port: 1}
rules:
  - MATCH,DIRECT
`)
	if err == nil {
		t.Fatal("invalid profile setup succeeded, want error")
	}
	if elapsed > 15*time.Second {
		t.Fatalf("invalid setup took %v to fail, want prompt error", elapsed)
	}
}

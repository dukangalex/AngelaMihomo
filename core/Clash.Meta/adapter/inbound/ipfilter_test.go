package inbound

import (
	"net"
	"net/netip"
	"testing"
)

func tcpAddr(ip string) net.Addr {
	return &net.TCPAddr{IP: net.ParseIP(ip), Port: 12345}
}

func TestIsRemoteAddrAllowedEmptyAllowList(t *testing.T) {
	oldAllowed, oldDisAllowed := AllowedIPs(), DisAllowedIPs()
	defer func() {
		SetAllowedIPs(oldAllowed)
		SetDisAllowedIPs(oldDisAllowed)
	}()

	// T79 regression: an empty (or never-set) allow list must mean
	// "no restriction", not "deny everything". The old implementation
	// denied every address in this state, which silently killed all
	// mixed/http/socks inbound connections.
	SetAllowedIPs(nil)
	SetDisAllowedIPs(nil)
	for _, ip := range []string{"127.0.0.1", "192.168.1.5", "10.0.0.9", "8.8.8.8", "::1", "2001:db8::1"} {
		if !IsRemoteAddrAllowed(tcpAddr(ip)) {
			t.Errorf("empty allow list: %s should be allowed", ip)
		}
	}

	SetAllowedIPs([]netip.Prefix{})
	for _, ip := range []string{"127.0.0.1", "192.168.1.5"} {
		if !IsRemoteAddrAllowed(tcpAddr(ip)) {
			t.Errorf("explicit empty allow list: %s should be allowed", ip)
		}
	}
}

func TestIsRemoteAddrAllowedLists(t *testing.T) {
	oldAllowed, oldDisAllowed := AllowedIPs(), DisAllowedIPs()
	defer func() {
		SetAllowedIPs(oldAllowed)
		SetDisAllowedIPs(oldDisAllowed)
	}()

	SetAllowedIPs([]netip.Prefix{netip.MustParsePrefix("192.168.0.0/16")})
	SetDisAllowedIPs(nil)
	if !IsRemoteAddrAllowed(tcpAddr("192.168.1.5")) {
		t.Error("192.168.1.5 is inside the allow list and should be allowed")
	}
	if IsRemoteAddrAllowed(tcpAddr("10.0.0.9")) {
		t.Error("10.0.0.9 is outside the allow list and should be dropped")
	}

	// The disallow list wins over the allow list.
	SetDisAllowedIPs([]netip.Prefix{netip.MustParsePrefix("192.168.1.0/24")})
	if IsRemoteAddrAllowed(tcpAddr("192.168.1.5")) {
		t.Error("192.168.1.5 is in the disallow list and should be dropped")
	}
	if !IsRemoteAddrAllowed(tcpAddr("192.168.2.5")) {
		t.Error("192.168.2.5 is allowed and not disallowed, should be allowed")
	}

	// Disallow list alone (empty allow list) still applies.
	SetAllowedIPs(nil)
	if IsRemoteAddrAllowed(tcpAddr("192.168.1.5")) {
		t.Error("192.168.1.5 is in the disallow list and should be dropped")
	}
	if !IsRemoteAddrAllowed(tcpAddr("203.0.113.7")) {
		t.Error("203.0.113.7 is not disallowed and the allow list is empty, should be allowed")
	}
}

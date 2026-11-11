package inbound

import (
	"net"
	"net/netip"

	C "github.com/metacubex/mihomo/constant"
)

var lanAllowedIPs []netip.Prefix
var lanDisAllowedIPs []netip.Prefix

func SetAllowedIPs(prefixes []netip.Prefix) {
	lanAllowedIPs = prefixes
}

func SetDisAllowedIPs(prefixes []netip.Prefix) {
	lanDisAllowedIPs = prefixes
}

func AllowedIPs() []netip.Prefix {
	return lanAllowedIPs
}

func DisAllowedIPs() []netip.Prefix {
	return lanDisAllowedIPs
}

// IsRemoteAddrAllowed reports whether a remote address may use the
// default LAN-facing listeners (http/mixed/socks).
//
// T79 fix: this used to be named IsRemoteAddrDisAllowed while actually
// computing "is allowed", and an empty allow list denied every
// address (prefixesContains of an empty list is always false). An
// empty allow list now means "no restriction", mirroring the
// allow-all prefixes in DefaultRawConfig: a sender that overwrites
// the list with an empty value must not turn this gate into
// "deny everything" (that silently killed every mixed-inbound
// connection, including the app's own subscription downloads).
func IsRemoteAddrAllowed(addr net.Addr) bool {
	m := C.Metadata{}
	if err := m.SetRemoteAddr(addr); err != nil {
		return false
	}
	ipAddr := m.AddrPort().Addr()
	if ipAddr.IsValid() {
		return isAllowed(ipAddr) && !isDisAllowed(ipAddr)
	}
	return false
}

func isAllowed(addr netip.Addr) bool {
	if len(lanAllowedIPs) == 0 {
		return true
	}
	return prefixesContains(lanAllowedIPs, addr)
}

func isDisAllowed(addr netip.Addr) bool {
	return prefixesContains(lanDisAllowedIPs, addr)
}

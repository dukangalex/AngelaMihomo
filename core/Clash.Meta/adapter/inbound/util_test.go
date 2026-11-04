package inbound

import (
	"fmt"
	"strings"
	"testing"

	"github.com/metacubex/mihomo/transport/socks5"
)

func TestParseSocksAddrDomainLengths(t *testing.T) {
	for length := 0; length <= 255; length++ {
		t.Run(fmt.Sprint(length), func(t *testing.T) {
			host := strings.Repeat("a", length)
			addr := append(socks5.Addr{socks5.AtypDomainName, byte(length)}, []byte(host)...)
			addr = append(addr, 0x12, 0x34)
			got := parseSocksAddr(addr)
			if got.Host != host || got.DstPort != 0x1234 {
				t.Fatalf("length %d: host=%q port=%d", length, got.Host, got.DstPort)
			}
		})
	}
}

func TestParseSocksAddrFQDN(t *testing.T) {
	host := "example.com."
	addr := append(socks5.Addr{socks5.AtypDomainName, byte(len(host))}, []byte(host)...)
	addr = append(addr, 0x01, 0xbb)
	got := parseSocksAddr(addr)
	if got.Host != "example.com" || got.DstPort != 443 {
		t.Fatalf("host=%q port=%d", got.Host, got.DstPort)
	}
}

func TestParseSocksAddrTruncated(t *testing.T) {
	// None of these may panic; all must yield empty host/IP and port 0.
	cases := map[string]socks5.Addr{
		"empty":            {},
		"domain type only": {socks5.AtypDomainName},
		"domain short":     {socks5.AtypDomainName, 10, 'a', 'b'},
		"domain no port":   {socks5.AtypDomainName, 3, 'a', 'b', 'c'},
		"domain half port": {socks5.AtypDomainName, 3, 'a', 'b', 'c', 0x01},
		"ipv4 short":       {socks5.AtypIPv4, 1, 2, 3},
		"ipv4 no port":     {socks5.AtypIPv4, 1, 2, 3, 4},
		"ipv6 short":       {socks5.AtypIPv6, 0x20, 0x01},
		"unknown type":     {0x09, 1, 2, 3, 4, 5, 6},
	}
	for name, addr := range cases {
		t.Run(name, func(t *testing.T) {
			got := parseSocksAddr(addr)
			if got.Host != "" || got.DstPort != 0 || got.DstIP.IsValid() {
				t.Fatalf("expected empty metadata, got host=%q ip=%v port=%d", got.Host, got.DstIP, got.DstPort)
			}
		})
	}
}

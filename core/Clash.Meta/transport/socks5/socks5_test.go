package socks5

import (
	"bytes"
	"testing"
)

func TestAddrStringValid(t *testing.T) {
	domain := Addr{AtypDomainName, 11}
	domain = append(domain, []byte("example.com")...)
	domain = append(domain, 0x01, 0xbb)
	if got := domain.String(); got != "example.com:443" {
		t.Fatalf("domain String() = %q", got)
	}

	ipv4 := Addr{AtypIPv4, 1, 1, 1, 1, 0x00, 0x35}
	if got := ipv4.String(); got != "1.1.1.1:53" {
		t.Fatalf("ipv4 String() = %q", got)
	}
}

func TestAddrStringTruncated(t *testing.T) {
	// None of these may panic.
	cases := map[string]Addr{
		"empty":            {},
		"domain type only": {AtypDomainName},
		"domain short":     {AtypDomainName, 10, 'a', 'b'},
		"domain no port":   {AtypDomainName, 3, 'a', 'b', 'c'},
		"ipv4 short":       {AtypIPv4, 1, 2, 3},
		"ipv4 no port":     {AtypIPv4, 1, 2, 3, 4},
		"ipv6 short":       {AtypIPv6, 0x20, 0x01},
	}
	for name, addr := range cases {
		t.Run(name, func(t *testing.T) {
			if got := addr.String(); got != "" {
				t.Fatalf("String() = %q, want empty", got)
			}
		})
	}
}

func TestAddrUDPAddrTruncated(t *testing.T) {
	cases := map[string]Addr{
		"empty":        {},
		"ipv4 short":   {AtypIPv4, 1, 2, 3},
		"ipv4 no port": {AtypIPv4, 1, 2, 3, 4},
		"ipv6 short":   {AtypIPv6, 0x20, 0x01},
		"domain":       {AtypDomainName, 3, 'a', 'b', 'c', 0, 53},
	}
	for name, addr := range cases {
		t.Run(name, func(t *testing.T) {
			if got := addr.UDPAddr(); got != nil {
				t.Fatalf("UDPAddr() = %v, want nil", got)
			}
		})
	}

	valid := Addr{AtypIPv4, 1, 1, 1, 1, 0x00, 0x35}
	if got := valid.UDPAddr(); got == nil || got.Port != 53 || got.IP.String() != "1.1.1.1" {
		t.Fatalf("UDPAddr() = %v", got)
	}
}

func TestReadAddrTruncated(t *testing.T) {
	// Domain header claims 10 bytes of host but the stream ends early.
	buf := make([]byte, MaxAddrLen)
	if _, err := ReadAddr(bytes.NewReader([]byte{AtypDomainName, 10, 'a', 'b'}), buf); err == nil {
		t.Fatal("expected error for truncated domain address")
	}
	if _, err := ReadAddr(bytes.NewReader([]byte{AtypIPv4, 1, 2}), buf); err == nil {
		t.Fatal("expected error for truncated IPv4 address")
	}
	if _, err := ReadAddr(bytes.NewReader([]byte{0x09, 1, 2, 3}), buf); err == nil {
		t.Fatal("expected error for unknown address type")
	}
}

func TestSplitAddrTruncated(t *testing.T) {
	if got := SplitAddr([]byte{}); got != nil {
		t.Fatalf("SplitAddr(empty) = %v", got)
	}
	if got := SplitAddr([]byte{AtypDomainName, 10, 'a'}); got != nil {
		t.Fatalf("SplitAddr(short domain) = %v", got)
	}
	if got := SplitAddr([]byte{AtypIPv6, 0x20}); got != nil {
		t.Fatalf("SplitAddr(short ipv6) = %v", got)
	}
}

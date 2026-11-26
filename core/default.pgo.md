# Core PGO profile

`default.pgo` is a Go CPU profile consumed automatically by `go build`
when it compiles the core main package in this directory (Go's default
`-pgo=auto` behaviour; verified in the built binary's build info as
`-pgo=default.pgo`). No build-script change is needed.

Provenance: collected 2026-11-25 from the official Mihomo v1.19.34
kernel under a sustained loopback bulk-TCP workload through an HTTP
proxy hop (30 s capture, 8.3 s of samples). Same-method A/B on the
loopback rig: +10.6% throughput, about -12% core CPU per GB versus the
non-PGO build (T295).

Refresh rule: re-collect and replace this file whenever the vendored
kernel version changes. A stale profile is safe (unmatched samples are
ignored) but gradually loses effect.

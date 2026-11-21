# Security Policy

## Supported versions

Only the latest release published on this repository's
[Releases](https://github.com/dukangalex/AngelaMihomo/releases) page is
supported with security fixes. Older releases do not receive backports;
please upgrade to the latest release before reporting an issue that may
already be fixed.

## Reporting a vulnerability

Please report vulnerabilities privately through GitHub's
[private vulnerability reporting](https://github.com/dukangalex/AngelaMihomo/security/advisories/new)
for this repository. Do not open a public issue for an unpatched
vulnerability.

A useful report includes:

- the affected version and platform (Android / Windows / macOS / Linux);
- a description of the issue and its security impact;
- steps to reproduce, or a proof of concept;
- any relevant logs — with subscription URLs, node credentials and other
  secrets removed before sending.

We aim to acknowledge a report within 7 days. Fixes are developed
privately where practical and shipped in a regular release; reporters
are credited in the release notes unless they prefer to stay anonymous.

## Scope notes

Areas of particular interest:

- the Windows helper service (privilege boundary between the app and the
  core process);
- the in-app update path and the signed data channel (geo data and the
  managed script);
- Android exported components and inter-app communication;
- handling of subscription and configuration data (which must stay on
  the device — see [DATA-FLOW.md](DATA-FLOW.md)).

## Data handling

What data the app reads, stores and sends is documented in
[DATA-FLOW.md](DATA-FLOW.md). The project's privacy rules are in
[PRIVACY-GUIDELINES.md](PRIVACY-GUIDELINES.md).

<h4 align="right">
  <a href="../README.md">简体中文</a> | <strong>English</strong> | <a href="README_ru.md">Русский</a> | <a href="README_fa.md">فارسی</a> | <a href="README_ja.md">日本語</a> | <a href="README_ko.md">한국어</a>
</h4>

<h1 align="center">♐ Angela Mihomo</h1>
<p align="center">
  <strong>A Mihomo client dressed in twelve zodiac themes</strong><br/>
  Default theme: Sagittarius · Indigo Night Arrow
</p>

## About this project

**Angela Mihomo** is a cross-platform proxy client built on the [Mihomo](https://github.com/MetaCubeX/mihomo) core, shipping one version with one feature set across Android, Windows, macOS and Linux. Its design language is a family of twelve zodiac themes — each constellation brings its own palette and star chart, in dark and light variants, with the interface floating over a starfield light field.

Four product principles guide the project: easy to use (import a subscription and it just runs), system-explicit (every kernel capability is on screen, with an explanation and a source), local-first privacy (whatever can stay on the device stays on the device, and logs and data are redacted before they are written), and long-term stability over decoration. It is developed and released independently under the GPL-3.0 license.

Release announcements: https://t.me/AngelaNexus

Discussion and feedback: https://t.me/AngelaMihomoGroup

Highlights:

* **Twelve zodiac themes**: Aries through Pisces, each themed on its constellation's element and imagery; Sagittarius · Indigo Night Arrow is the default. Cards are translucent glass over the star chart, and switching a theme re-skins the whole app from one token set.
* **True chained proxying**: both the entry hop and the exit landing may be proxy groups, and the exit may be selected from another profile; if the entry dies the whole chain goes down with it — traffic never falls back to a direct connection around the entry.
* **System-explicit leak protection**: WebRTC blocking, China public-DNS direct routing, ad blocking and related explicit rules, unified with the chain policy and effective out of the box. In rule mode, China traffic goes direct and everything else goes through the proxy, guaranteed by app-injected rules that subscription rules cannot pierce.
* **Local-first privacy**: the exit IP's country, region, ASN and carrier are resolved from a local database with zero outbound queries; no ads, no telemetry; update checks point only at this repository.
* **Managed mode with a built-in script**: turn managed mode on for a profile and the bundled script generates its proxy groups and rules (off by default, strictly opt-in per profile). The script's content stays customizable; its canonical copy lives in this repository and updates ship with app releases.
* **Independent package identity**: the Android application id is `app.angelabettbox`, so it can be installed alongside other clients; the id stays stable so existing installs upgrade in place.
* **Core and data alignment**: the bundled Mihomo core tracks official Mihomo releases (currently v1.19.34), and built-in rule data comes from the official MetaCubeX/meta-rules-dat source.

## Downloads

Get packages for your platform from this repository's **[Releases](https://github.com/dukangalex/AngelaMihomo/releases)** page (Windows, Linux, macOS, Android, Android TV). Distribution is GitHub-only: the Windows installer is not commercially code-signed and the macOS build is not notarized.

**Migrating from another build (Android)**: since v1.19.7-chain.1 this app uses its own package name and installs alongside other builds; export a backup in the other app first, then import it here.

## Acknowledgements

* **[Bettbox](https://github.com/appshubcc/Bettbox)** — the original project this codebase descends from; thanks to appshubcc and all contributors.
* **[FlClash](https://github.com/chen08209/FlClash)** — the lineage origin.
* **[Mihomo](https://github.com/MetaCubeX/mihomo)** — the core engine.

## License

GPL-3.0 — see [LICENSE](../LICENSE). Full source lives in this repository.

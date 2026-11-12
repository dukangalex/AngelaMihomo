<h4 align="right">
  <a href="README.md">简体中文</a> | <strong>English</strong>
</h4>

<p align="center">
  <img src="snapshots/banner.svg" alt="AngelaMihomo" width="880" />
</p>

<h1 align="center">AngelaMihomo</h1>

<p align="center">
  <strong>A Mihomo client that just works once you import a subscription</strong><br/>
  Current release 1.19.7-chain.18 · Bundled Mihomo core 1.19.34 · GPL-3.0
</p>

## What it is

AngelaMihomo is a cross-platform proxy client built on the Mihomo core, running on Android, Windows, macOS and Linux. It is made for one specific job: someone who knows nothing about proxies imports a subscription or a node, and the app runs the way they intend; someone who does know the field can find every capability of the core in the UI, explained and adjustable.

The app version and the bundled core version are shown on the About page. The core tracks official Mihomo releases, and all built-in rule data comes from the official MetaCubeX source.

## How we build it

- **Zero-knowledge first**: sane defaults out of the box — after import, a usable node is picked automatically and routing plus China-network adaptation are already in place, with no technical decisions asked of you.
- **Chained proxying**: each profile can carry its own chain; entry and exit hops may both be proxy groups, the exit may come from another profile, and a broken chain rejects direct fallback instead of silently bypassing.
- **Privacy first**: no permission is requested unless necessary, no ads, no user data collection. Leak protection is an explicit rule set (WebRTC blocking, DNS anti-pollution, ad blocking) wired together with the chain policy and on by default.
- **Nothing hidden**: if the core can do it, it is in the UI with a short explanation; every behavior has exactly one setting that governs it — no conflicting switches.
- **Stability over speed**: every release is tried on a real device first. Slow is acceptable; broken is not.

## Download and install

Packages are published only on this repository's [Releases](https://github.com/dukangalex/AngelaMihomo/releases) page. Get them nowhere else, and check the SHA-256 values provided there.

| Platform | Requirement | Notes |
|---|---|---|
| Android | 8.0+ | ARMv8 / ARMv7 / x86_64 / Universal builds; Android TV supported |
| Windows | 8.1+ | x64 / arm64, plus a Compatible build for older hardware |
| macOS | 12.0+ | Intel / Apple Silicon |
| Linux | Kernel 5.4+ | x64 / arm64 |

Our distribution limits, stated plainly: this project is **not on any app store** and is distributed via GitHub only; the **Windows installer is not code-signed** (on the SmartScreen prompt choose "More info" → "Run anyway"); the **macOS build is not notarized** (first launch: right-click the app in Finder → Applications and choose "Open"). The full source is in this repository — audit it, or build it yourself.

The Android application id is `app.angelabettbox`, so the app installs alongside other clients. Migrating from another build: export a backup there first, then import it here.

## Three steps to run

1. Download the package for your platform above and install it.
2. On the Profiles page, paste or scan your subscription (a single node works too).
3. Flip the switch on the home page. Node selection, routing and leak protection run on the defaults from there.

## Features

- **Connection**: rule / global / direct modes, TUN and system proxy, profile switching that takes effect while running.
- **Chained proxying**: per-profile entry and exit hops, cross-profile exits and group hops.
- **Profiles**: multiple profiles, automatic updates, import normalization that tidies vendor formats into one usable config.
- **Routing and protection**: a rule baseline of China traffic direct and everything else proxied; WebRTC blocking, ad blocking and DNS anti-pollution working as one set.
- **Core capabilities, surfaced**: speed tests, health checks, DNS, sniffing and other core parameters are visual settings with explanations, each with a clear rule for when a change takes effect.
- **Scripting**: external JS override scripts, with a visual UI for script switches (see Developers).
- **Your data stays yours**: profiles and backups export locally, with WebDAV backup and restore.

## Contact

- Release channel (versions and updates): Telegram [@AngelaNexus](https://t.me/AngelaNexus)
- Discussion group (usage and feedback): Telegram [AngelaMihomoGroup](https://t.me/AngelaMihomoGroup)
- Bugs and suggestions: this repository's [Issues](https://github.com/dukangalex/AngelaMihomo/issues) — please include the version and steps to reproduce.

## Developers

Build environment, regression testing and per-platform packaging are documented in [DEVELOPMENT.md](DEVELOPMENT.md) (Flutter 3.47.x, Go, Rust; `dart setup.dart` assembles core and app).

**Script UI adaptation**: an override script opts into the visual switch UI with one declaration line —

```js
const Compatible_With_Mihomo = { ruleOptionsEnable: true };
```

Policy-group switches in a script can be named via `policyGroupOptions`; unnamed switches are grouped under "Other settings". This convention comes from the Mihomo script ecosystem (e.g. AIsouler's [MyClash](https://github.com/AIsouler/MyClash) script shares); scripts following it work as-is.

## Acknowledgements

- [Bettbox](https://github.com/appshubcc/Bettbox): the codebase this project descends from — thanks to appshubcc and its contributors.
- [FlClash GUI](https://github.com/chen08209/FlClash): the origin of the lineage — thanks to its author for the pioneering work.
- [Mihomo Core](https://github.com/MetaCubeX/mihomo): the core bundled in this app — thanks to the MetaCubeX team.

Open-source projects consulted and learned from during development: [Zashboard](https://github.com/Zephyruso/zashboard), [CMFA](https://github.com/MetaCubeX/ClashMetaForAndroid), [Sparkle](https://github.com/xishang0128/sparkle), [SFA](https://github.com/SagerNet/sing-box-for-android), [HUSI](https://github.com/xchacha20-poly1305/husi), [V2rayN](https://github.com/2dust/v2rayN).

## License

Released under the [GPL-3.0](LICENSE) license; the complete source is this repository.

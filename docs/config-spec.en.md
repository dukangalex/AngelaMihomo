# Configuration Specification (Single Spec)

> Chinese version: [config-spec.zh-CN.md](config-spec.zh-CN.md)
>
> Status: finalized (2026-11-10, T81). This document is the project's **only**
> configuration assembly specification. Any configuration behavior that
> conflicts with it is a defect; change this document before changing the
> assembly order.

## 1. Principles

- Every behavior has exactly one authoritative source, one assembly path, and
  one precedence order. Two writers for the same field, forkable dual storage,
  or merge order by convention are all defects.
- The effective configuration is assembled bottom-up through a six-layer
  pipeline; higher layers win, and every final value must trace back to
  exactly one layer.

## 2. The six-layer pipeline

| Layer | Name | Contents and owner |
| --- | --- | --- |
| L0 | Subscription as-is | The parsed raw configuration of the current profile (subscription / local file); the assembly base draft. |
| L1 | Script | The user script's result over the subscription (bridge scripted-config channel), applied above L0 and before the App patch. |
| L2 | App settings section takeover | The App model's (ClashConfig) dns / ntp / sniffer / experimental sections take over **wholesale**: when the App section is sent, the subscription section plays no part. General scalars likewise come from the App model. There are no gate flags. |
| L3 | Profile-level overrides | Overrides belonging to the current profile only: policy-group editor overrides (group-overrides), node exclude filters, etc. |
| L4 | China-adaptation derivation | System-explicit options (interception switches) derive the runtime mode and rule tail: with any interception item on, mode is forced to rule with a synthesized MATCH tail. Mode may only be derived in this layer. In rule mode with chinaDirect on, the China-routing invariant also applies (T87): the China-direct rules always precede every routable profile rule, and the final MATCH must resolve to a group that carries a proxy choice — a bridge-side tail guard rewrites or appends it when the MATCH is missing or points at a builtin action, a direct-only group, or a disabled group; a valid profile MATCH is kept verbatim. |
| L5 | Generation guards | Final validity checks and clamping (port conflicts, empty-value fallback, invalid-item removal). Guards only; no new semantics. |
| L6 | Bridge normalization | Platform normalization just before handing the config to the kernel (registry in §6). Runs last, never writes back; App-side stored values are unchanged. |

Group selection has exactly one authority: the App's selectedMap. The kernel
side `store-selected` is always `false`; the kernel never writes selection
state back.

## 3. Pairwise precedence

| # | Relation | Notes |
| --- | --- | --- |
| 1 | L3 editor group url > L0 subscription group url | Only an explicitly written editor url overrides; clearing it restores the subscription value. |
| 2 | L3 editor group url > App global test url | Explicit edit beats the global rewrite (batch 1, C-2). |
| 3 | App global test url > L0 subscription group url | Without an explicit url and with the rewrite on, prepareSetup rewrites the group url to the App test url. |
| 4 | L3 editor other fields > L0 same-named group fields | Group overrides are sent wholesale; per-field the editor value wins. |
| 5 | L2 four sections wholesale > L0 same-named sections | dns/ntp/sniffer/experimental are replaced as whole sections, never merged per-field (batch 3). |
| 6 | L2 general scalars > L0 same-named keys | Including external-ui url/name, geodata-loader, geodata-mode — the App model is the only source (batch 3, R-2/R-4). |
| 7 | L3 editor exclude-filter replaces the L0 value, then unions with the App-global node-exclude-filter | The editor value replaces; the global value is unioned in over the same scope the global filter always had (provider-backed groups, i.e. a non-nil use list) (batch 2, C-3). |
| 8 | L1 script > L0 | Script output covers the subscription as-is; L2 and above assemble on top of it. |
| 9 | L4 mode derivation > user-selected mode | With any interception item on, the derived value (rule) wins; setup and hot update share one derivation function (batch 1, C-1). |
| 10 | selectedMap (App) is the only selection authority | store-selected is always false (batch 1, R-1a). |
| 11 | L5 guards > every layer | Invalid values are clamped or removed at the guard; no layer may bypass it. |
| 12 | L6 platform transforms run last | They only affect the copy handed to the kernel, never the App model or the subscription. |
| 13 | Hot-update projection ⊆ setup parameters, same source | Hot-update (UpdateParams) fields carry the same values as setup; fields outside the projection take effect at the timing annotated per §7 (batch 3, P-5). |
| 14 | Defaults are defined only in the App model | Bridge base defaults only fill keys absent from the model JSON (unreachable when the model serializes fully); no second default site (batch 3, R-5). |
| 15 | China-direct rules > every routable profile rule; MATCH tail guard > an unqualified profile MATCH | Rule mode with chinaDirect on only (T87): same-category profile rules are replaced and other categories sort after the China-direct pair; when the MATCH target carries no proxy choice (builtin action / direct-only group / disabled group) or MATCH is missing, the tail guard rewrites/appends the first proxy-carrying group. LAN/private direct routing is an address property and is out of scope. |

## 4. Section takeover and the inheritance migration (batch 3)

- The dns / ntp / sniffer / experimental sections lose their override gate
  flags; the App model always takes over wholesale.
- One-time upgrade migration (version marker `specMigrationVersion`, runs
  once): for a section whose legacy gate was **on**, the App model was
  already authoritative and is kept as-is. For a section whose gate was
  **off**, the model value never took effect, so at upgrade the App model is
  first seeded from the **current profile's subscription** section and then
  takes over — the effective configuration after upgrade matches the
  pre-upgrade one section by section. When the subscription has no such
  section, the App model's current value stands (factory defaults for
  untouched users).
- Decision rule: gate off means "this section was never overridden by the
  App" — under a closed gate no model value ever took effect, so replacing
  it cannot change the effective configuration. This is the most robust
  rule the existing persisted data supports.
- The migration result is ordinary App model data; later user edits behave
  as usual. A failed migration never blocks startup; it is logged and the
  watermark still advances.

## 5. Single source of defaults (R-5)

- All defaults are defined only in the App model
  (`lib/models/clash_config.dart`); UI and assembly reference model
  constants and never carry their own literals.
- Removed duplicate defaults: the `geodata-loader` literal (state.dart),
  the `geodata-mode` literal (state.dart), and the external-ui url/name
  literals (state.dart) — all now carried by model fields (geodata-mode is
  a new model field defaulting to `false`, matching the old assembly
  literal).
- The bridge (core) bases takeover sections on KDF defaults, filling only
  keys absent from the model JSON; since the App model serializes fully,
  the base is unreachable in practice and exists only as a defense.

## 6. L6 platform normalization registry

| Transform | Platform | Notes |
| --- | --- | --- |
| Provider paths forcibly rewritten to `md5(url)` | all | S-2 ruling: a subscription provider's local path is never decided by the subscription's own value. |
| DNS listen `:53` → `:10053` | Android | Unprivileged-port normalization; under specific conditions the listen address narrows to `127.0.0.1`. |
| NTP `write-to-system` forced `false` | Android | The platform has no system-time write permission. |
| tun `auto-route` / `auto-detect-interface` platform-forced values | desktop / Android respectively | Decided by platform capability, not by subscription or App. |
| Linux system-DNS changes go through the backup–readback–rollback channel | Linux | T78 ruling: back up the original state before changing, verify by read-back afterwards, roll back automatically on failure, and report at two levels on the page. |
| route-exclude-address → route-address-set shape transform | as the kernel requires | Field-shape normalization; the semantic set is unchanged. |

## 7. Hot-update projection and effective timing (P-5)

- Hot-update parameters (UpdateParams) share the setup parameters' source:
  mode uses the same derivation (batch 1), and interface-name is sent with
  the same desktop condition as setup (completed in batch 3).
- Fields outside the hot-update projection take effect at the next setup
  (core restart / configuration reload); the App annotates the affected
  settings with "Takes effect after the core restarts": UA,
  keep-alive-interval, keep-alive-idle, bind-address, lan-allowed-ips,
  lan-disallowed-ips, store-fake-ip, and port / socks-port / redir-port /
  tproxy-port (mixed-port is in the projection and applies live); plus
  every field of the ntp, sniffer, and experimental sections and the
  tunnels and hosts editing surfaces (annotated in T89 D-01 with the
  same marker).
- Some pages trigger a full re-setup on save (user authentication, GEO
  auto-update settings); their fields apply on save and are not in the
  list above.

## 8. Convergence status of the audit's 19 items

| Class | Count | Status |
| --- | --- | --- |
| Conflicts (C) | 4 | All converged: C-1 same-source mode, C-2 explicit group url wins, C-3 exclude-filter merge semantics, C-4 chain floor echo (batches 1–2). |
| Redundancies (R) | 5 | All converged: four gate flags removed (R-2, batch 3), store-selected off (R-1a, batch 1), dual-write fields cleared, single source of defaults (R-5, batch 3). |
| Unclear precedence (P) | 5 | All converged: §3 fixes every pair; P-5 same-source hot update (batch 3), with effective-timing annotations converged over the general page scalars (batch 3) plus ntp, sniffer, experimental, tunnels, and hosts annotated with the same marker (T89 D-01). |
| Shadow paths (S) | 5 | All converged or registered: geosite wipe-out removed (S-1, batch 1), orphan-group hint (S-5, batch 2), provider-path and platform transforms registered in §6 (S-2/S-4). |

## 9. Verification

- End-to-end assembly snapshot: `core/spec_snapshot_test.go` (dns section
  takeover, group url chain, exclude-filter merge); any layer reordering
  fails it.
- Mode synthesis chain: `test/providers/update_params_mode_test.dart`,
  `test/common/system_explicit_test.dart`.
- Migration and takeover assembly: `test/common/spec_migration_test.dart`,
  `test/common/setup_params_takeover_test.dart`.

# AngelaMihomo 隐私与功能完整性指引

> 本文件是 AngelaMihomo 的项目长远发展指引之一，2026-11-17 由项目所有者定版。
> 项目的第一硬性规定是六条地基——隐私、数据安全、高效节能、运行平稳、能力显式、开箱即用，
> 六条没有主次之分，都是项目地基。本文件是其中「隐私」一条的展开，
> 与自有化总目标、数据自建仓通则、单一规范原则共同构成项目的长期约束。
> 本文件的修订须经项目所有者拍板，并在此处留痕。

## 一句话总纲

**功能全保留、功能不变残、隐私不泄露；做法是不忽悠、可追溯、公开透明。**

隐私靠架构与数据流治理实现，不靠删减功能实现，也不靠削弱功能实现。

## 第一条 功能完整性：不删减现有功能

- 现有功能不因隐私顾虑或实现难度被删减。遇到隐私冲突，从架构、数据流与仲裁层解决，不许以删除功能掩盖问题。
- 历史上已经项目所有者拍板砍除的项目（AI 解读层、流媒体解锁探测）属存档例外，不翻案；此后任何功能下线，须经项目所有者逐项拍板。
- 新增功能与保留功能适用同一标准：账面写下的能力必须真实落实，做不到的不上账。

## 第二条 开启态隐私：用户开启任何功能，隐私都不泄露

- 用户开启功能不等于隐私豁免。功能在开启状态下，其数据外发必须同时满足五条：
  1. **最小必要**：只发送完成功能所必需的那份数据；
  2. **对象单一且必需**：只发送给功能本身必需的那个对象；
  3. **不留存**：结果不作功能之外的留存；
  4. **不落日志**：敏感数据不写入日志、诊断与导出（既有脱敏规则全程适用）；
  5. **不捎带**：不顺带发送任何与功能无关的信息（真实 IP、设备标识、订阅内容、配置内容等）。
- 功能本身必需的数据（例如 IP 风险检测中待查询的出口 IP）属于功能数据，可以发送，但仅限于此，不多一分。
- 每个功能都要按开启状态做数据流复核：实际外发与上述五条逐项对照，复核记录可查。
- 能本地完成的计算与查询一律本地完成；必须外发的，优先经用户已连接的代理通道发出，避免服务端直见用户真实 IP。

## 第三条 功能本体不阉割：隐私加固不得把功能做残

- 隐私加固不许降低功能的核心能力、数据完整度、数据新鲜度与可用性。功能名义保留、实际做弱或做成摆设，视为违反本指引。
- 每项加固必须做前后对照验证：相同输入、相同条件下，比较加固前后的功能效果；效果打折即不通过。
- 当某项加固暂时做不到「隐私与效果双全」时，停下并报告项目所有者拍板，不许静默降级功能，也不许静默放行泄露。

## 第四条 诚实与透明：不忽悠、可追溯、公开透明

- **不忽悠**：文档、界面文案与发布说明中的每一条隐私声明，必须与代码的实际行为一致，且有实证支撑；无实证不声明。发现声明与实现不符，按缺陷处理，当期修正（改实现或改声明）。
- **可追溯**：每一项隐私结论都要能追溯到代码落点与实测证据。本项目的全部外发端点与逐功能数据流均有清单记录，验收与复核以清单为底账。
- **公开透明**：本仓库公开维护《数据流向清单》（什么数据、在什么时机、发给谁、为什么），随版本更新；季度隐私复扫的结论以摘要形式公开。项目本身开源，任何人可对照代码核验上述声明。
- **引用必致谢（包括自己的）**：项目实际引用、集成、调用或借用的一切成果——第三方成果与项目作者自有其他项目的成果，一视同仁——均须在致谢区如实列全、注明出处；不因「是自己的」就默默吸收，也不以清除第三方露出为由删署名。致谢同时承担溯源职能：经自有独立仓分发的数据，致谢仍须注明其原始官方来源——自有仓是分发渠道，不是源头；来源链（原始来源 → 自有仓 → 本项目）必须完整可查。

## 落地机制

- **新功能准入**：上线前完成数据流自查（在《数据流向清单》中增项，并按第二条做开启态复核），未过自查不上线。
- **发版门槛**：每版发布前核对《数据流向清单》与声明文案是否同步更新；季度隐私复扫不通过，冻结下一版发布，直至修复复验通过。
- **首批落地**：全量端点盘点、逐功能开启态复核、系统云备份口径显式化、直连拉取改经代理、第三方 CDN 镜像自有化等事项，由项目台账 T198 跟踪实施。

---

# AngelaMihomo Privacy and Feature-Integrity Guidelines

> This document is one of the long-term development guidelines of AngelaMihomo, adopted by the project owner on 2026-11-17.
> The project's first hard rule is its six foundation pillars — privacy, data security, efficiency, stability, explicit capabilities, and out-of-the-box usability — equal in rank, none subordinate to another. This document elaborates the privacy pillar, and together with the self-sufficiency goal, the self-hosted data-repository rule, and the single-source-of-truth principle, it forms the project's long-term constraints.
> Amendments require the project owner's decision and are recorded here.

## The principle in one sentence

**Every feature kept, no feature hollowed out, no privacy leaked — with honesty, traceability, and public transparency as the method.**

Privacy is achieved through architecture and data-flow governance, never by removing features and never by weakening them.

## Article 1 — Feature integrity: no existing feature is removed

- No existing feature is removed over privacy concerns or implementation difficulty. Privacy conflicts are resolved at the architecture, data-flow, and arbitration layers; deleting a feature to mask a conflict is prohibited.
- Removals previously decided by the project owner (the AI interpretation layer and the streaming-unlock probe) are archived exceptions and are not revisited. Any future feature removal requires the project owner's item-by-item approval.
- New and retained features are held to the same standard: every capability written on the books must actually work; a capability that cannot be delivered is not put on the books.

## Article 2 — Privacy in the enabled state: turning a feature on never leaks privacy

- Enabling a feature is not a privacy waiver. While a feature is on, any data it sends out must satisfy all five conditions:
  1. **Minimum necessary**: only the data required for the feature to do its job;
  2. **Single, necessary recipient**: only to the party the feature inherently requires;
  3. **No retention**: results are not kept beyond the feature's own purpose;
  4. **No logging**: sensitive data never enters logs, diagnostics, or exports (existing redaction rules apply throughout);
  5. **No piggybacking**: nothing unrelated rides along (real IP, device identifiers, subscription contents, configuration contents, and so on).
- Data that is itself the object of the feature (for example, the exit IP whose risk the user asks to check) is feature data and may be sent — that much, and no more.
- Every feature undergoes a data-flow review in its enabled state: actual outbound data is checked item by item against the five conditions, and the review is recorded.
- Computation and lookups that can be done locally are done locally. Where sending is unavoidable, traffic preferentially goes through the user's already-connected proxy channel, so servers do not see the user's real IP directly.

## Article 3 — No hollowing out: privacy hardening must not cripple a feature

- Privacy hardening must not degrade a feature's core capability, data completeness, data freshness, or usability. A feature that survives in name but is weakened or reduced to decoration violates this guideline.
- Every hardening change is verified by before-and-after comparison: same inputs, same conditions, feature effect compared; any loss of effect fails the change.
- When a hardening change cannot yet achieve both full privacy and full effect, work stops and the project owner decides; silently degrading the feature or silently accepting the leak are both prohibited.

## Article 4 — Honesty and transparency: no bluffing, traceable, publicly transparent

- **No bluffing**: every privacy statement in documentation, UI copy, and release notes must match the code's actual behavior and be backed by evidence; no evidence, no statement. A statement found inconsistent with the implementation is treated as a defect and fixed in the current cycle (fix the implementation or fix the statement).
- **Traceable**: every privacy conclusion must trace back to a code location and measured evidence. All outbound endpoints and per-feature data flows are kept in an inventory, which is the ledger for acceptance and review.
- **Publicly transparent**: this repository publicly maintains a Data Flow Inventory (what data, at what moment, to whom, and why), updated with each release; quarterly privacy re-scan conclusions are published in summary form. The project is open source, so anyone can verify these statements against the code.
- **Every reference is credited, including our own**: everything the project actually references, integrates, calls, or borrows — third-party work and the project author's own work from other projects alike — is listed in the acknowledgements with its source. Nothing is silently absorbed because "it is ours", and no attribution is removed in the name of clearing third-party traces. Attribution also serves provenance: data distributed through our own independent repositories is still credited to its original official source — our repository is the distribution channel, not the origin — and the full chain (original source → own repository → this project) must remain traceable.

## Enforcement

- **New-feature admission**: before release, a feature completes a data-flow self-check (an entry added to the Data Flow Inventory, plus an enabled-state review under Article 2). No self-check, no release.
- **Release gate**: before each release, the Data Flow Inventory and all public statements are checked for synchronization; a failed quarterly privacy re-scan freezes the next release until fixed and re-verified.
- **First batch**: the full endpoint inventory, per-feature enabled-state reviews, explicit system cloud-backup posture, routing direct fetches through the proxy, and self-hosting third-party CDN mirrors are tracked as item T198 in the project ledger.

<!--
  发布说明模板：每版必填，不许留空。
  模板里的占位符必须在打 tag 之前逐项换成本版文案；
  构建流水线会检查成稿与频道公告稿，残留任何占位符都会直接失败，
  防止旧版文案再次随新版发出（chain.28 发布说明带旧文的教训）。
  下载链接中的版本号记号由流水线自动替换，不要改动。
  图片资产规矩：截图等图片入库前一律剥除 EXIF（设备型号、拍摄
  时间、定位等一概不随仓公开），发布前复核 snapshots/ 全量为零
  EXIF（T244）。
-->

# Angela Mihomo 正式版本发布 / Stable Release

### 自有化定型：数据、字体、图标、工具全部自有自研 / Fully self-owned: data, fonts, icons and tools — all in-house

本版是 AngelaMihomo 的自有化定型版：chain.28 已把数据收归自有仓分发，本版再进一步——随包字体换成开源授权的 Noto Sans SC、Windows 回环豁免工具改为完全自研、Android TV 横幅与 macOS 版权署名归位、Android 系统云备份显式关闭、脚本更新通道改为校验失败即拒用、桌面小部件协议键换自有命名。至此，运行时依赖与随包组件全部自有，或采用授权清晰的开源成果，不再依赖任何无授权的第三方组件。功能一项不少：自有化靠替换与自研完成，不靠砍功能。
(This release is the self-ownership definitive edition of AngelaMihomo. chain.28 already moved all data distribution to our own repositories; this release goes further — the bundled font is now the openly licensed Noto Sans SC, the Windows loopback-exemption tool is now fully developed in-house, the Android TV banner and macOS copyright carry our own identity, Android system cloud backup is explicitly off, the script update channel fails closed on any verification error, and the home-widget protocol keys moved to our own namespace. Runtime dependencies and bundled components are now all our own, or openly licensed with clear terms — no unauthorized third-party component remains. No feature removed: self-ownership was achieved by replacement and in-house development, never by cutting features.)

> 仍在 chain.25 或更早版本的用户请注意 chain.26 的一次性迁移：应用标识已改为 app.angelamihomo，升级前请先在旧版导出配置、装新版后导入。详见 chain.26 发布说明。
> (Still on chain.25 or earlier? See the chain.26 release notes for the one-time app-identity migration: export your configuration before upgrading and import it afterwards.)

### ✨ 本版亮点 / What's new in this build

- **自有化定型 / Fully self-owned**：内核兜底数据源、脚本组图标全部改指自有仓，运行时不依赖任何第三方在线服务；随包组件全部自有或授权清晰，第三方只出现在致谢里。
  (Kernel fallback data sources and script group icons all point at our own repositories, and the app depends on no third-party online service at runtime; every bundled component is our own or clearly licensed, with third parties appearing only in the acknowledgements.)
- **Windows 回环工具自研 / Loopback tool, now in-house (Windows)**：用于放行商店应用访问本机代理端口的回环豁免工具改为完全自研（20 KB，另带命令行模式），不再随包分发来源与授权不明的第三方二进制。
  (The loopback-exemption tool that lets Store apps reach the local proxy port is now fully developed in-house (20 KB, with a command-line mode besides the GUI); the Windows package no longer ships a third-party binary of unclear provenance and licensing.)
- **字体换新 / A new bundled font**：随包中文字体由 HarmonyOS Sans SC 换为 Noto Sans SC（SIL 开源字体授权 OFL-1.1，可自由分发），字形观感与字距、行高略有变化。原随包副本是经子集化修改的版本、不满足其授权的分发条件，本版一并改正，许可全文随包附带。
  (The bundled Chinese font changes from HarmonyOS Sans SC to Noto Sans SC (SIL Open Font License 1.1, freely redistributable); glyph shapes and text metrics differ slightly. The previously bundled copy was a subsetted, modified build that did not meet its licence's redistribution terms — now corrected, with the full licence text shipped in the package.)
- **隐私再加固 / Privacy hardened**：Android 系统备份显式关闭，含订阅与凭据的明文配置不再随系统云备份离开设备；脚本与数据通道校验失败一律拒用，绝不将就加载未验签内容。
  (Android system backup is explicitly disabled, so plaintext configuration (subscriptions, credentials) never leaves the device via cloud backup; script and data channels fail closed — unverified content is never loaded.)
- **品牌与版权归位 / Branding and copyright set right**：Android TV 横幅换自有标识、macOS 版权署名更正为 AngelaMihomo、默认 User-Agent 改为自有标识、站点图标等文案与实现对齐；桌面小部件的内部协议键同步换成自有命名，用户无感。
  (The Android TV banner carries our own artwork, the macOS copyright now names AngelaMihomo, the default User-Agent leads with our own identity, and site-icon copy matches the implementation; internal home-widget protocol keys moved to our own namespace as well — invisible to users.)
- **官方整包＋签名校验 / Official bundle, signature-verified**：内置规则数据包改指 core-bundle-2026.12，采用 MetaCubeX 官方整包（来源链完整可查），数据文件附 SHA-256 清单与 Ed25519 签名，构建与运行时双重校验。
  (The bundled rule data package now points at core-bundle-2026.12, built on the official MetaCubeX package with a fully traceable source chain; data files ship with a SHA-256 manifest and Ed25519 signature, verified at build time and at runtime.)
- **内核 / Core**：Mihomo 1.19.34

### ✍️ 签名说明 / Signing

- Windows 安装包暂未签名，安装时 Windows SmartScreen 会提示，请点击"更多信息" → "仍要运行"。
  (Windows installer is currently unsigned. Click "More info" → "Run anyway" on SmartScreen.)
- 每个安装包都在本页附有 SHA-256 校验值，请核对后安装。

---
### ⬇️ Download / 下载链接

**Note: For desktop CPUs from 2012 or earlier, please download the Compatible version**
<br>**注意：桌面端2012年同期及之前的CPU，需要使用Compatible兼容版本**

**常用设备平台，android-arm64-v8a, windows-amd64, macos-arm64**

---

<div align="left">

| **OS/ 系统** | **Requirements / 版本要求** | **Direct Links / 点击直链下载** |
|:---:|:---|:---|
| <img src="https://cdn.jsdelivr.net/gh/dukangalex/AngelaMihomo@main/assets/route_svg/Apple.svg" alt="macOS" width="28"/> | macOS 12.0+ | <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-macos-arm64.dmg"><img src="https://img.shields.io/badge/DMG-Apple%20Silicon-000000?logo=apple&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-macos-amd64.dmg"><img src="https://img.shields.io/badge/DMG-Intel%20x64-00A9E0?logo=apple&logoColor=white&style=flat-square&labelColor=222222"></a> |
| <img src="https://cdn.jsdelivr.net/gh/dukangalex/AngelaMihomo@main/assets/route_svg/Android.svg" alt="Android" width="28"/> | Android 8.0+<br>*(Compatible with Android TV)* |<a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-android-arm64-v8a.apk"><img src="https://img.shields.io/badge/APK-ARMv8-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-android-x86_64.apk"><img src="https://img.shields.io/badge/APK-x64-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a><br><a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-android-armeabi-v7a.apk"><img src="https://img.shields.io/badge/APK-ARMv7-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-android-universal.apk"><img src="https://img.shields.io/badge/APK-Universal-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a> |
| <img src="https://cdn.jsdelivr.net/gh/dukangalex/AngelaMihomo@main/assets/route_svg/Windows.svg" alt="Windows" width="28"/> | Windows 8.1+<br>*(Compatible for Older CPU)* | <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-windows-amd64-setup.exe"><img src="https://img.shields.io/badge/Setup-x64-0078D7?logo=windows&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-windows-arm64-setup.exe"><img src="https://img.shields.io/badge/Setup-ARM64-0078D7?logo=windows&logoColor=white&style=flat-square&labelColor=222222"></a><br><a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-windows-amd64-compatible-setup.exe"><img src="https://img.shields.io/badge/Setup-Compatible%20x64-555555?logo=windows&logoColor=white&style=flat-square&labelColor=222222"></a> |
| <img src="https://cdn.jsdelivr.net/gh/dukangalex/AngelaMihomo@main/assets/route_svg/Linux.svg" alt="Linux" width="28"/> | Linux Kernel 5.4+<br>*(Compatible for Older CPU)* | <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-linux-amd64.AppImage"><img src="https://img.shields.io/badge/AppImage-x64-f84e29?logo=linux&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-linux-amd64.deb"><img src="https://img.shields.io/badge/DEB-x64-A81D33?logo=debian&logoColor=white&style=flat-square&labelColor=222222"></a><br><a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-linux-arm64.deb"><img src="https://img.shields.io/badge/DEB-ARM64-A81D33?logo=debian&logoColor=white&style=flat-square&labelColor=222222"> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-linux-amd64-compatible.deb"><img src="https://img.shields.io/badge/DEB-Compatible%20x64-555555?logo=debian&logoColor=white&style=flat-square&labelColor=222222"></a> |
---
</div>

### 🐛 Feedback / 问题反馈

> **Note / 提示：**
> Detailed and well-structured issues will be prioritized(logs / reproduction steps)<br>
> 书写认真、信息完整（包含必要的复现步骤和日志）的 issues 会被优先处理和对待

**Bug Report / 提交故障**: [Click Here / 点击这里](https://github.com/dukangalex/AngelaMihomo/issues/new?template=bug_report.yml)
**Feature Request / 需求建议**: [Click Here / 点击这里](https://github.com/dukangalex/AngelaMihomo/issues/new?template=feature_request.yml)

<br>

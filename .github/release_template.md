# Angela Mihomo 正式版本发布 / Stable Release

### 🖥️ 本版专项：Windows 安装焕新 / This release: a clean Windows install experience

Windows 安装器此前会沿用旧版的安装目录（装过 Bettbox 时代版本的用户会被装回 Bettbox 文件夹）。本版起：安装时弹出路径选择页、默认装入 Angela Mihomo 目录、升级安装自动清理旧 Bettbox 助手服务与旧安装目录（配置与数据不受影响）；静默卸载不再被数据确认弹窗卡住。应用功能与 chain.26 相同，内核保持 Mihomo v1.19.34。
(Windows installers used to inherit the previous install folder, which sent users coming from Bettbox-era builds back into a Bettbox directory. From this release: the installer always shows the destination page, defaults to an Angela Mihomo folder, and cleans up the legacy Bettbox helper service and old install directory on upgrade — configuration and data are untouched. Silent uninstalls no longer hang on the data-removal prompt. App features are unchanged from chain.26; the core stays at Mihomo v1.19.34.)

> 仍在 chain.25 或更早版本的用户请注意 chain.26 的一次性迁移：应用标识已改为 app.angelamihomo，升级前请先在旧版导出配置、装新版后导入。详见 chain.26 发布说明。
> (Still on chain.25 or earlier? See the chain.26 release notes for the one-time app-identity migration: export your configuration before upgrading and import it afterwards.)

### ✨ 本版亮点 / What's new in this build

- **安装路径自由选 / Choose your install path**：安装向导必定显示目标目录页，预填 Angela Mihomo 默认目录，可自由更改到任何位置
  (The destination page always appears, pre-filled with the Angela Mihomo default; pick any folder you like)
- **旧残留自动清理 / Legacy cleanup**：升级安装自动删除旧的 BettboxHelperService 服务注册与旧安装目录，不再留下 Bettbox 痕迹
  (Upgrades remove the stale BettboxHelperService registration and the old install directory automatically)
- **静默卸载不卡住 / Silent uninstall never hangs**：非交互卸载默认保留用户数据，不再等待确认弹窗
  (Non-interactive uninstalls keep user data by default instead of waiting on a prompt)
- **回环工具自有化 / Loopback tool renamed**：WindowsLoopbackManager 更名为 AngelaMihomoLoopbackManager
  (WindowsLoopbackManager is now AngelaMihomoLoopbackManager)
- **构建流水线加固 / Pipeline hardening**：全部第三方 GitHub Action 固定到提交哈希，工作流令牌权限收紧到最小
  (Every third-party GitHub Action is pinned to a commit hash and workflow token permissions are reduced to the minimum)
- **内核 / Core**：Mihomo v1.19.34（与 chain.26 相同，本版为安装与维护专项）

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
| <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/apple/apple-original.svg" alt="macOS" width="28"/> | macOS 12.0+ | <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-macos-arm64.dmg"><img src="https://img.shields.io/badge/DMG-Apple%20Silicon-000000?logo=apple&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-macos-amd64.dmg"><img src="https://img.shields.io/badge/DMG-Intel%20x64-00A9E0?logo=apple&logoColor=white&style=flat-square&labelColor=222222"></a> |
| <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/android/android-original.svg" alt="Android" width="28"/> | Android 8.0+<br>*(Compatible with Android TV)* |<a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-android-arm64-v8a.apk"><img src="https://img.shields.io/badge/APK-ARMv8-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-android-x86_64.apk"><img src="https://img.shields.io/badge/APK-x64-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a><br><a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-android-armeabi-v7a.apk"><img src="https://img.shields.io/badge/APK-ARMv7-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-android-universal.apk"><img src="https://img.shields.io/badge/APK-Universal-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a> |
| <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/windows11/windows11-original.svg" alt="Windows" width="28"/> | Windows 8.1+<br>*(Compatible for Older CPU)* | <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-windows-amd64-setup.exe"><img src="https://img.shields.io/badge/Setup-x64-0078D7?logo=windows&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-windows-arm64-setup.exe"><img src="https://img.shields.io/badge/Setup-ARM64-0078D7?logo=windows&logoColor=white&style=flat-square&labelColor=222222"></a><br><a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-windows-amd64-compatible-setup.exe"><img src="https://img.shields.io/badge/Setup-Compatible%20x64-555555?logo=windows&logoColor=white&style=flat-square&labelColor=222222"></a> |
| <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/linux/linux-original.svg" alt="Linux" width="28"/> | Linux Kernel 5.4+<br>*(Compatible for Older CPU)* | <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-linux-amd64.AppImage"><img src="https://img.shields.io/badge/AppImage-x64-f84e29?logo=linux&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-linux-amd64.deb"><img src="https://img.shields.io/badge/DEB-x64-A81D33?logo=debian&logoColor=white&style=flat-square&labelColor=222222"></a><br><a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-linux-arm64.deb"><img src="https://img.shields.io/badge/DEB-ARM64-A81D33?logo=debian&logoColor=white&style=flat-square&labelColor=222222"> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-VERSION-linux-amd64-compatible.deb"><img src="https://img.shields.io/badge/DEB-Compatible%20x64-555555?logo=debian&logoColor=white&style=flat-square&labelColor=222222"></a> |
---
</div>

### 🐛 Feedback / 问题反馈

> **Note / 提示：**
> Detailed and well-structured issues will be prioritized(logs / reproduction steps)<br>
> 书写认真、信息完整（包含必要的复现步骤和日志）的 issues 会被优先处理和对待

**Bug Report / 提交故障**: [Click Here / 点击这里](https://github.com/dukangalex/AngelaMihomo/issues/new?template=bug_report.yml)
**Feature Request / 需求建议**: [Click Here / 点击这里](https://github.com/dukangalex/AngelaMihomo/issues/new?template=feature_request.yml)

<br>

# Angela Mihomo 正式版本发布 / Stable Release

### ⚠️ 升级必读：应用标识已变更，先导出再安装 / Important: new app identity — export before installing

本版起应用标识改为自有的 app.angelamihomo，新版会作为一个全新的应用安装，不会覆盖旧版。升级步骤：① 在旧版中导出配置（备份与恢复）② 安装本版 ③ 在新版中导入配置 ④ 确认一切正常后再卸载旧版。这是一次性迁移，之后的版本恢复覆盖升级。
(From this release on, the app uses its own identity, app.angelamihomo, and installs as a new app instead of updating the old one. To upgrade: export your configuration from the old app, install this release, import the configuration, and remove the old app only after everything checks out. This is a one-time migration; later releases update in place again.)

### ✨ 本版亮点 / What's new in this build

- **星辰大海主题家族 / The Starry Seas theme family**：两大系列共 27 套主题——十二星座（每套带本星座守护神与名牌，守护神仰望顶部星图）与人类深空探索（从东方一号到 DART 共 15 件深空事件，各带事件名牌）；默认主题射手座·靛夜飞箭
  (Two series, 27 themes in total: the twelve zodiac signs, each with its guardian and nameplate beneath its own star chart, and fifteen landmark events of human deep-space exploration from Vostok 1 to DART, each with its event nameplate. Default: Sagittarius, Indigo Night Arrow)
- **隐私本地化 / Privacy, kept on-device**：地理信息全部本地查询（城市库经项目自有数据仓分发、校验后落盘本地查询），移除全部在线地理问询；图标改走项目自有仓；WebDAV 凭据改为 AES-256-GCM 加密存储
  (All geo lookups are local now: the city database ships through the project's own data repository, is verified and stored on-device, and every online geo query is gone. Icons come from the project's own repository, and WebDAV credentials are stored with AES-256-GCM encryption)
- **应用内更新 / In-app update**：发现新版后可在应用内下载，校验 SHA-256 后直接调起安装，失败自动回落浏览器
  (New releases can be downloaded inside the app, verified against their SHA-256, and installed directly; any failure falls back to the browser)
- **每个选项都有说明 / Every option explains itself**：全 App 选项补齐通俗说明，工具箱各页加页内说明；选项小字常亮易读；失败提示逐条写明原因与解决办法
  (Every option across the app now carries a plain-language explanation, the toolbox pages explain themselves, option captions stay lit and readable, and failure notices state the cause and the fix)
- **界面与手感 / Interface touches**：配置页添加按钮移入顶栏；测速提示统一 5 秒消失；链式代理切换去掉迟滞；城市库改内存映射，内存占用更低
  (The add button moved into the profiles top bar, speed-test notices dismiss after five seconds, chain-proxy switching lost its lag, and the city database is memory-mapped to cut memory use)
- **沿用并完善 / Carried forward**：首页合并卡与提示灯、开启自动测速、配置卡状态标记、按配置文件链式代理、系统显式规则三模式生效、DNS 悬空引用热修与存量自动迁移
  (The merged home card and status light, auto speed test on start, profile card badges, per-profile chain proxy, system-explicit rules in all three modes, and the DNS dangling-reference hotfix with automatic migration of stored settings)
- **内核 / Core**：Mihomo v1.19.34

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

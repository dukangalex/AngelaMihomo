# Angela Mihomo 预览版本发布 / Preview Release
**注意：预览版本通常包含最新的功能修复增强或不确定性，如遇问题请提交issue[[反馈]](https://github.com/dukangalex/AngelaMihomo/issues/new?template=bug_report.yml)联系社区交流。**

<div align="left">

### 📣 发布频道

版本发布与更新通知见 Telegram 频道：https://t.me/AngelaNexus

---
</div>

### ✨ 本版内容 / What's in this preview（chain.30 预览）

- **浅色纯色十二生肖 / Light solid zodiac series（本版夺目点）**：纯色主题新增浅色一组，与深色纯色十二生肖一一对应——浅底、同生肖深色线条水印，在设置页「纯色生肖」组内分深色 / 浅色两组选用。
  (The solid-color theme family gains a light set, one-to-one with the dark solid zodiac twelve — light backgrounds with the same zodiac line-art watermark in a deeper tone. Pick them in Settings under the solid zodiac group, now split into dark and light.)
- **首页卡片新版式 / Home card, redesigned**：首页顶部合并卡重新排版，配置名、更新时间、到期日与用量完整显示不截断；合并配置的到期日与流量改为跟随同一家订阅并标明来源，不再出现日期是这家、流量是那家的对不上。
  (The merged home card is re-laid out so name, update time, expiry and usage always show in full; for merged profiles the expiry date and traffic now come from the same member subscription, with the source named.)
- **安全审计整改 / Security audit fixes**：两轮外部安全审计的整改全部并入——Windows 助手服务密钥权限收紧、命名管道与配置导入边界加固、本地落盘字段加密、发布流水线签名材料隔离、构建工具钉版校验等。
  (Both rounds of external security-audit fixes land here: tightened Windows helper service key ACLs, hardened named-pipe and config-import boundaries, field-level encryption for on-disk preferences, release-signing material isolation in CI, and pinned, hash-verified build tools.)
- **默认更注重隐私 / Privacy-first defaults**：出厂默认 DNS 改为跟随系统，不再写死公共解析服务；规则数据的运行时完整性校验与脚本完整性校验补齐，校验不过的内容一律拒用。
  (The factory-default DNS now follows the system instead of hard-coded public resolvers; runtime integrity checks for bundled rule data and managed scripts are completed — anything that fails verification is refused.)
- **内核 / Core**：Mihomo 1.19.34（与 chain.29 同内核）

### ⚠️ 已知问题 / Known issues

- **Windows 静默升级的安装目录（修复中）**：在自定义目录（如 D 盘）安装后，通过静默方式升级可能不沿用原目录、落到默认目录，并使旧目录被移除；遇到时请运行新目录下的程序，配置数据不受影响（配置在用户目录下独立保存）。修复完成前，建议升级时运行安装包并确认安装目录为原目录。
  (On Windows, if you installed into a custom directory (e.g. drive D:), a silent upgrade may not keep that directory and may install into the default location instead, removing the old one. Your configuration is unaffected (it lives separately under your user profile); until the fix ships, run the installer and confirm the target directory when upgrading.)

### ⬇️ Download / 下载链接

**Note: For desktop CPUs from 2012 or earlier, please download the Compatible version**
<br>**注意：桌面端2012年同期及之前的CPU，需要使用Compatible兼容版本**

**常用设备平台，android-arm64-v8a, windows-amd64, macos-arm64**

---

<div align="left">

| **OS/ 系统** | **Requirements / 版本要求** | **Direct Links / 点击直链下载** |
|:---:|:---|:---|
| <img src="https://cdn.jsdelivr.net/gh/dukangalex/AngelaMihomo@main/assets/route_svg/Apple.svg" alt="macOS" width="28"/> | macOS 12.0+ | <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-macos-arm64.dmg"><img src="https://img.shields.io/badge/DMG-Apple%20Silicon-000000?logo=apple&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-macos-amd64.dmg"><img src="https://img.shields.io/badge/DMG-Intel%20x64-00A9E0?logo=apple&logoColor=white&style=flat-square&labelColor=222222"></a> |
| <img src="https://cdn.jsdelivr.net/gh/dukangalex/AngelaMihomo@main/assets/route_svg/Android.svg" alt="Android" width="28"/> | Android 8.0+<br>*(Compatible with Android TV)* |<a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-android-arm64-v8a.apk"><img src="https://img.shields.io/badge/APK-ARMv8-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-android-x86_64.apk"><img src="https://img.shields.io/badge/APK-x64-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a><br><a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-android-armeabi-v7a.apk"><img src="https://img.shields.io/badge/APK-ARMv7-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-android-universal.apk"><img src="https://img.shields.io/badge/APK-Universal-32AF6A?logo=android&logoColor=white&style=flat-square&labelColor=222222"></a> |
| <img src="https://cdn.jsdelivr.net/gh/dukangalex/AngelaMihomo@main/assets/route_svg/Windows.svg" alt="Windows" width="28"/> | Windows 8.1+<br>*(Compatible for Older CPU)* | <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-windows-amd64-setup.exe"><img src="https://img.shields.io/badge/Setup-x64-0078D7?logo=windows&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-windows-arm64-setup.exe"><img src="https://img.shields.io/badge/Setup-ARM64-0078D7?logo=windows&logoColor=white&style=flat-square&labelColor=222222"></a><br><a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-windows-amd64-compatible-setup.exe"><img src="https://img.shields.io/badge/Setup-Compatible%20x64-555555?logo=windows&logoColor=white&style=flat-square&labelColor=222222"></a> |
| <img src="https://cdn.jsdelivr.net/gh/dukangalex/AngelaMihomo@main/assets/route_svg/Linux.svg" alt="Linux" width="28"/> | Linux Kernel 5.4+<br>*(Compatible for Older CPU)* | <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-linux-amd64.AppImage"><img src="https://img.shields.io/badge/AppImage-x64-f84e29?logo=linux&logoColor=white&style=flat-square&labelColor=222222"></a> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-linux-amd64.deb"><img src="https://img.shields.io/badge/DEB-x64-A81D33?logo=debian&logoColor=white&style=flat-square&labelColor=222222"></a><br><a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-linux-arm64.deb"><img src="https://img.shields.io/badge/DEB-ARM64-A81D33?logo=debian&logoColor=white&style=flat-square&labelColor=222222"> <a href="https://github.com/dukangalex/AngelaMihomo/releases/download/vVERSION/AngelaMihomo-BASE_VERSION-linux-amd64-compatible.deb"><img src="https://img.shields.io/badge/DEB-Compatible%20x64-555555?logo=debian&logoColor=white&style=flat-square&labelColor=222222"></a> |
---
</div>

### 🐛 Feedback / 问题反馈

> **Note / 提示：**
> Detailed and well-structured issues will be prioritized(logs / reproduction steps)<br>
> 书写认真、信息完整（包含必要的复现步骤和日志）的 issues 会被优先处理和对待

**Bug Report / 提交故障**: [Click Here / 点击这里](https://github.com/dukangalex/AngelaMihomo/issues/new?template=bug_report.yml)
**Feature Request / 需求建议**: [Click Here / 点击这里](https://github.com/dukangalex/AngelaMihomo/issues/new?template=feature_request.yml)

<br>

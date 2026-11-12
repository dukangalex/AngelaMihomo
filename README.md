<h4 align="right">
  <strong>简体中文</strong> | <a href="README.en.md">English</a>
</h4>

<p align="center">
  <img src="snapshots/banner.svg" alt="AngelaMihomo" width="880" />
</p>

<h1 align="center">AngelaMihomo</h1>

<p align="center">
  <strong>导入订阅，打开就能用的 Mihomo 客户端</strong><br/>
  当前版本 1.19.7-chain.18 · 内置 Mihomo 内核 1.19.34 · GPL-3.0 开源
</p>

## 这是什么

AngelaMihomo 是一个基于 Mihomo 内核的跨平台代理客户端，运行在 Android、Windows、macOS、Linux 四个平台。它要解决的是一件很具体的事：不懂代理概念的人，把订阅或节点信息导入进来，就能按自己的意图跑起来；懂行的人，则能把内核的每一项能力都在界面里找到、点开、调明白。

应用版本与内置内核版本在「关于」页直接可见，内核跟随 Mihomo 官方版本对齐，内置规则数据全部取自 MetaCubeX 官方源。

## 我们的取舍

- **零基础优先**：默认配置开箱即对——导入后自动选可用节点、规则与中国网络适配默认到位，中途不需要你做技术决策。
- **链式代理**：每个配置可独立设置链路，入口与出口都可选用策略组作跳点，出口可跨配置选择；链路失效时入口组自动拒绝直连，不让流量悄悄绕行。
- **隐私优先**：非必要权限一律不索取，无广告，不收集用户数据；防泄漏是一整套显式规则（WebRTC 拦截、DNS 防污染、广告拦截）与链路统一联动，默认生效。
- **能力不藏着**：内核能做的都摆到界面上，每项设置带简明说明；任何选项只有一个生效口径，不留互相打架的开关。
- **长期平稳运行**：每一版先经真机试用再发布，宁可慢，不发问题版本。

## 下载与安装

安装包只在本仓库的 [Releases](https://github.com/dukangalex/AngelaMihomo/releases) 页面发布，请认准这一处来源，并核对页面提供的 SHA-256 校验值。

| 平台 | 要求 | 说明 |
|---|---|---|
| Android | 8.0+ | ARMv8 / ARMv7 / x86_64 / Universal 四种包，TV 大屏亦适配 |
| Windows | 8.1+ | x64 / arm64，老设备另有 Compatible 兼容版 |
| macOS | 12.0+ | Intel / Apple Silicon |
| Linux | 内核 5.4+ | x64 / arm64 |

先把分发短板说在前面：本项目**未上架任何应用商店**，只经 GitHub 分发；**Windows 安装包未做代码签名**，SmartScreen 提示时点「更多信息 → 仍要运行」；**macOS 未做 Apple 公证**，首次打开请在「访达 → 应用程序」里右键点应用选「打开」。源码全量在本仓库，可自行审计后构建。

Android 包名为 `app.angelabettbox`，可与其他同类客户端并存安装；从其他版本迁移时，先在原应用导出备份，再在本应用导入恢复。

## 三步上手

1. 按上表下载对应平台的安装包并安装。
2. 在「配置」页粘贴或扫码导入你的订阅（也可以导入单个节点信息）。
3. 回到首页打开开关。剩下的——选节点、分流、防泄漏——按默认配置自动工作。

## 功能面

- **连接**：规则 / 全局 / 直连三种模式，TUN 与系统代理，运行中切换配置自动生效。
- **链式代理**：按配置独立设置入口与出口跳点，支持跨配置出口与策略组跳点。
- **订阅**：多配置管理、自动更新、导入归一化（把各家格式整理成统一可用的配置）。
- **分流与防护**：中国流量直连、非中国流量代理的规则基线；WebRTC 拦截、广告拦截、DNS 防污染成套生效。
- **内核能力显式化**：测速、健康检查、DNS、嗅探等内核参数均有可视化设置项与说明，改动按明确的生效口径执行。
- **脚本扩展**：支持外置 JS 覆写脚本，并为脚本开关提供可视化界面适配（见「开发者」一节）。
- **数据自理**：配置与备份可导出、可 WebDAV 备份恢复，数据始终在你自己手里。

## 联系方式

- 发布频道（版本与更新通知）：Telegram [@AngelaNexus](https://t.me/AngelaNexus)
- 交流群（使用交流与问题反馈）：Telegram [AngelaMihomoGroup](https://t.me/AngelaMihomoGroup)
- 缺陷与建议：本仓库 [Issues](https://github.com/dukangalex/AngelaMihomo/issues)，提交时请附版本与复现步骤。

## 开发者

构建环境、回归测试与各平台打包说明见 [DEVELOPMENT.md](DEVELOPMENT.md)（Flutter 3.47.x、Go、Rust，`dart setup.dart` 一键装配核心与应用）。

**脚本 UI 适配**：覆写脚本在首行声明即可联动内置可视化开关——

```js
const Compatible_With_Mihomo = { ruleOptionsEnable: true };
```

脚本开关中的策略组类开关可用 `policyGroupOptions` 点名归类，未点名的自动归入「其他设置」。这套约定源自 Mihomo 系脚本生态的通行做法（如 AIsouler 的 [MyClash](https://github.com/AIsouler/MyClash) 脚本分享），支持该约定的脚本可直接使用。

## 致谢

- [Bettbox](https://github.com/appshubcc/Bettbox)：本项目的代码渊源，感谢 appshubcc 与其贡献者。
- [FlClash GUI](https://github.com/chen08209/FlClash)：谱系起源，感谢原作者的开创性工作。
- [Mihomo Core](https://github.com/MetaCubeX/mihomo)：本应用内置的内核，感谢 MetaCubeX 团队。
- [DB-IP](https://db-ip.com)：IP 城市库数据来源（DB-IP Free IP-to-City Lite，按 CC BY 4.0 许可使用），应用内的地理信息全部在本地查询、不外发。

开发中参考与借鉴的开源项目：[Zashboard](https://github.com/Zephyruso/zashboard)、[CMFA](https://github.com/MetaCubeX/ClashMetaForAndroid)、[Sparkle](https://github.com/xishang0128/sparkle)、[SFA](https://github.com/SagerNet/sing-box-for-android)、[HUSI](https://github.com/xchacha20-poly1305/husi)、[V2rayN](https://github.com/2dust/v2rayN)。

## 开源协议

本项目以 [GPL-3.0](LICENSE) 协议开源，完整源码即本仓库。

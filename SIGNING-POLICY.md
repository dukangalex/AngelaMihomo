# 签名与分发说明 / Signing & Distribution

本文件说明 AngelaMihomo 各平台安装包的签名现状，与发布模板口径一致。如本文件与实际发布物不符，以实际发布物为准并请提交 Issue 指出。

- **Android**：安装包以本项目发布密钥签名，证书指纹固定不变，历版可覆盖升级；校验方式为比对 Releases 页面提供的 SHA-256。
- **Windows**：安装包暂未做代码签名。SmartScreen 提示时点「更多信息 → 仍要运行」。下载后请核对 SHA-256。
- **macOS**：安装包未做 Apple 公证。首次打开请在「访达 → 应用程序」中右键点应用选「打开」。
- **Linux**：无签名机制，认准本仓库 Releases 页面下载并核对 SHA-256。

分发渠道只有一条：本仓库 GitHub Releases。任何其他来源的同名安装包与本项目无关。

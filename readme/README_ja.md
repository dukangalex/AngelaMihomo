<h4 align="right">
  <a href="../README.md">简⁠体⁠中⁠文</a> | <a href="README_en.md">English</a> | <a href="README_ru.md">Русский</a> | <a href="README_fa.md">فارسی</a> | <strong>日⁠本⁠語</strong> | <a href="README_ko.md">한⁠국⁠어</a>
</h4>

<h1 align="center">⚡ Angela Mihomo</h1>
<p align="center">
  <strong>チェーンプロキシを強化した Mihomo クライアント</strong>
</p>

## このプロジェクトについて

**Angela Mihomo** は [Mihomo](https://github.com/MetaCubeX/mihomo) コアを基盤とするクロスプラットフォームのプロキシクライアントで、チェーンプロキシ、システムレベルのリーク対策、すぐに使える体験に重点を置いています。GPL-3.0 ライセンスのもとで独立に開発・公開されています。

リリース告知: https://t.me/AngelaNexus

* **チェーンプロキシ強化: 入口と出口の両方にプロキシグループを指定でき、出口は別プロファイルからも選択可能。入口グループが空の場合は直接接続へのフォールバックを自動で拒否します。**
* **システム明示型リーク対策: WebRTC ブロック、中国のパブリック DNS への直接接続、広告ブロックなどの明示ルールをチェーン方針と統一し、初期状態で有効です。**
* **独立したパッケージ ID: Android の application id は `app.angelamihomo` で、他のクライアントと併存インストールが可能。chain.26 で ID を変更したため、旧版ユーザーは旧アプリで設定をエクスポートし、新アプリにインポートしてください（初回のみ）。**
* **コアとデータの整合: 同梱 Mihomo コアは公式リリースに追随（現在 v1.19.34）。ランタイムデータはすべて本プロジェクト独自のデータリポジトリ [angelamihomo-geo](https://github.com/dukangalex/angelamihomo-geo) から配布されます — ソースは公式リリースのみ、各ファイルにハッシュ一覧と署名を付与し、アプリが毎日自動更新します。**

## ダウンロード

各プラットフォーム向けパッケージは本リポジトリの **[Releases](https://github.com/dukangalex/AngelaMihomo/releases)** ページから入手できます（Windows、Linux、macOS、Android、Android TV）。

**他のビルドからの移行（Android）**: v1.19.7-chain.1 以降、本アプリは独自のパッケージ名を使用し、他のビルドと併存インストールできます。先に元のアプリでバックアップをエクスポートし、本アプリでインポートしてください。

## 謝辞

* **[Bettbox](https://github.com/appshubcc/Bettbox)** — 本コードベースの源流となったプロジェクト。appshubcc とすべての貢献者に感謝します。
* **[FlClash](https://github.com/chen08209/FlClash)** — 系譜の起源。
* **[Mihomo](https://github.com/MetaCubeX/mihomo)** — コアエンジン。

## ライセンス

GPL-3.0 — [LICENSE](../LICENSE) を参照。完全なソースコードは本リポジトリにあります。

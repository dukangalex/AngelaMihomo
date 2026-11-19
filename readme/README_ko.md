<h4 align="right">
  <a href="../README.md">简⁠体⁠中⁠文</a> | <a href="README_en.md">English</a> | <a href="README_ru.md">Русский</a> | <a href="README_fa.md">فارسی</a> | <a href="README_ja.md">日⁠本⁠語</a> | <strong>한⁠국⁠어</strong>
</h4>

<h1 align="center">⚡ Angela Mihomo</h1>
<p align="center">
  <strong>체인 프록시가 강화된 Mihomo 클라이언트</strong>
</p>

## 프로젝트 소개

**Angela Mihomo**는 [Mihomo](https://github.com/MetaCubeX/mihomo) 코어 기반의 크로스플랫폼 프록시 클라이언트로, 체인 프록시, 시스템 수준의 유출 방지, 설치 즉시 사용 가능한 경험에 중점을 둡니다. GPL-3.0 라이선스로 독립적으로 개발 및 배포됩니다.

릴리스 공지: https://t.me/AngelaNexus

* **체인 프록시 강화: 진입점과 출구 모두 프록시 그룹을 지정할 수 있고, 출구는 다른 프로필에서도 선택할 수 있습니다. 진입 그룹이 비어 있으면 직접 연결 우회를 자동으로 거부합니다.**
* **시스템 명시적 유출 방지: WebRTC 차단, 중국 공용 DNS 직접 연결, 광고 차단 등 명시적 규칙을 체인 정책과 통합하여 기본으로 적용합니다.**
* **독립 패키지 ID: Android application id는 `app.angelamihomo`로 다른 클라이언트와 함께 설치할 수 있습니다. chain.26에서 ID가 변경되어, 기존 사용자는 구 앱에서 설정을 내보낸 뒤 새 앱으로 가져와야 합니다(최초 1회).**
* **코어 및 데이터 정합: 내장 Mihomo 코어는 공식 릴리스를 따르고(현재 v1.19.34), 모든 런타임 데이터는 프로젝트 자체 데이터 저장소 [angelamihomo-geo](https://github.com/dukangalex/angelamihomo-geo)에서 배포됩니다 — 공식 출처만 사용하고, 각 파일마다 해시 목록과 서명을 갖추며, 앱이 매일 자동 업데이트합니다.**

## 다운로드

플랫폼별 패키지는 이 저장소의 **[Releases](https://github.com/dukangalex/AngelaMihomo/releases)** 페이지에서 받을 수 있습니다(Windows, Linux, macOS, Android, Android TV).

**다른 빌드에서 마이그레이션(Android)**: v1.19.7-chain.1부터 이 앱은 자체 패키지 이름을 사용하며 다른 빌드와 함께 설치됩니다. 먼저 기존 앱에서 백업을 내보낸 뒤 이 앱에서 가져오세요.

## 감사의 글

* **[Bettbox](https://github.com/appshubcc/Bettbox)** — 이 코드베이스의 원류가 된 프로젝트. appshubcc와 모든 기여자에게 감사합니다.
* **[FlClash](https://github.com/chen08209/FlClash)** — 계보의 기원.
* **[Mihomo](https://github.com/MetaCubeX/mihomo)** — 코어 엔진.

## 라이선스

GPL-3.0 — [LICENSE](../LICENSE) 참조. 전체 소스 코드는 이 저장소에 있습니다.

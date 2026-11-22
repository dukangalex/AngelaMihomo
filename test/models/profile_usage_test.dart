import 'package:angelamihomo/common/app_localizations.dart';
import 'package:angelamihomo/l10n/l10n.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// T223: the home card's expiry date and traffic figure follow the
/// subscription source of the current profile. For a merged profile
/// both come from one and the same source — the earliest expiring
/// one — and the card names that source beside the date, instead of
/// pairing one source's date with an aggregate traffic figure.
void main() {
  setUpAll(() => AppLocalizations.load(const Locale('zh', 'CN')));

  final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  const gb = 1024 * 1024 * 1024;

  Profile profileWith({
    SubscriptionInfo? info,
    Map<String, SubscriptionInfo> providers = const {},
    String url = 'https://example.com/sub',
  }) {
    return Profile(
      id: 'p1',
      label: 'P',
      url: url,
      autoUpdateDuration: const Duration(hours: 24),
      subscriptionInfo: info,
      providerSubscriptions: providers,
    );
  }

  String trafficText(int used, int total) =>
      '${TrafficValue(value: used).show} / ${TrafficValue(value: total).show}';

  test('单订阅配置：到期与流量即该订阅自身，不带来源名', () {
    final expire = nowSec + 30 * 86400;
    final profile = profileWith(
      info: SubscriptionInfo(
        upload: 10 * gb,
        download: 5 * gb,
        total: 100 * gb,
        expire: expire,
      ),
    );
    final usage = ProfileUsage.of(profile)!;
    expect(usage.isMulti, isFalse);
    expect(usage.primarySourceName, isNull);
    expect(usage.expireAt, DateTime.fromMillisecondsSinceEpoch(expire * 1000));
    expect(usage.cardUsageText, trafficText(15 * gb, 100 * gb));
    expect(usage.cardUsageText, usage.usageText);
  });

  test('单来源的合并形态（只有一个 provider 来源）同样不带来源名', () {
    final expire = nowSec + 30 * 86400;
    final profile = profileWith(
      providers: {
        'Solo': SubscriptionInfo(
          upload: 1 * gb,
          download: 2 * gb,
          total: 50 * gb,
          expire: expire,
        ),
      },
    );
    final usage = ProfileUsage.of(profile)!;
    expect(usage.isMulti, isFalse);
    expect(usage.primarySourceName, isNull);
    expect(usage.cardUsageText, trafficText(3 * gb, 50 * gb));
  });

  test('多订阅合并：到期与流量同取最早到期那家，并给出其来源名', () {
    final betaExpire = nowSec + 10 * 86400;
    final profile = profileWith(
      providers: {
        'Alpha': SubscriptionInfo(
          upload: 1 * gb,
          download: 1 * gb,
          total: 50 * gb,
          expire: nowSec + 60 * 86400,
        ),
        'Beta': SubscriptionInfo(
          upload: 20 * gb,
          download: 10 * gb,
          total: 200 * gb,
          expire: betaExpire,
        ),
        'Gamma': SubscriptionInfo(
          upload: 3 * gb,
          download: 3 * gb,
          total: 0,
          expire: 0,
        ),
      },
    );
    final usage = ProfileUsage.of(profile)!;
    expect(usage.isMulti, isTrue);
    expect(usage.primaryEntry.key, 'Beta');
    expect(usage.primarySourceName, 'Beta');
    expect(
      usage.expireAt,
      DateTime.fromMillisecondsSinceEpoch(betaExpire * 1000),
    );
    // Traffic figures are Beta's own, not the cross-source aggregate.
    expect(usage.cardUsageText, trafficText(30 * gb, 200 * gb));
    expect(usage.cardUsageText, isNot(usage.usageText));
    expect(usage.primaryUsed, 30 * gb);
    expect(usage.primaryTotal, 200 * gb);
  });

  test('多订阅合并且都无到期信息：回落第一家，到期与流量仍同源', () {
    final profile = profileWith(
      providers: {
        'First': SubscriptionInfo(
          upload: 4 * gb,
          download: 4 * gb,
          total: 80 * gb,
          expire: 0,
        ),
        'Second': SubscriptionInfo(
          upload: 9 * gb,
          download: 9 * gb,
          total: 40 * gb,
          expire: 0,
        ),
      },
    );
    final usage = ProfileUsage.of(profile)!;
    expect(usage.primaryEntry.key, 'First');
    expect(usage.primarySourceName, 'First');
    expect(usage.expireAt, isNull);
    expect(usage.cardUsageText, trafficText(8 * gb, 80 * gb));
  });

  test('无订阅信息：不生成用量对象，卡片不显示到期（保持现状）', () {
    final urlProfile = profileWith();
    expect(ProfileUsage.of(urlProfile), isNull);
    expect(urlProfile.usageExpireText(null), isNull);

    final fileProfile = profileWith(url: '');
    expect(ProfileUsage.of(fileProfile), isNull);
    expect(fileProfile.usageExpireText(null), appLocalizations.localFile);
  });
}

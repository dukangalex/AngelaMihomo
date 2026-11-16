import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// T141 (T57 carryback): the profile card's subscription warnings —
/// expired, expiring within seven days, or under a tenth of the
/// traffic remaining.
void main() {
  final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  const gb = 1024 * 1024 * 1024;

  test('到期超过七天且流量充足时无警示', () {
    final info = SubscriptionInfo(
      upload: 10 * gb,
      download: 10 * gb,
      total: 100 * gb,
      expire: nowSec + 30 * 86400,
    );
    expect(info.isExpired, isFalse);
    expect(info.isExpiringSoon, isFalse);
    expect(info.isLowTraffic, isFalse);
    expect(info.hasWarning, isFalse);
  });

  test('七天内到期触发临期警示', () {
    final info = SubscriptionInfo(
      upload: 0,
      download: 0,
      total: 100 * gb,
      expire: nowSec + 3 * 86400,
    );
    expect(info.isExpiringSoon, isTrue);
    expect(info.hasWarning, isTrue);
  });

  test('已过期只算过期、不算临期', () {
    final info = SubscriptionInfo(
      upload: 0,
      download: 0,
      total: 100 * gb,
      expire: nowSec - 86400,
    );
    expect(info.isExpired, isTrue);
    expect(info.isExpiringSoon, isFalse);
    expect(info.hasWarning, isTrue);
  });

  test('剩余流量低于一成触发流量警示（剩余恰好一成不触发）', () {
    final low = SubscriptionInfo(
      upload: 50 * gb,
      download: 46 * gb,
      total: 100 * gb,
      expire: nowSec + 30 * 86400,
    );
    expect(low.remainingBytes, 4 * gb);
    expect(low.isLowTraffic, isTrue);
    expect(low.hasWarning, isTrue);

    final edge = SubscriptionInfo(
      upload: 50 * gb,
      download: 40 * gb,
      total: 100 * gb,
      expire: nowSec + 30 * 86400,
    );
    expect(edge.remainingBytes, 10 * gb);
    expect(edge.isLowTraffic, isFalse);
  });

  test('无总量或无到期信息时不误报', () {
    const unlimited = SubscriptionInfo(upload: 5, download: 5);
    expect(unlimited.isLowTraffic, isFalse);
    expect(unlimited.isExpiringSoon, isFalse);
    expect(unlimited.hasWarning, isFalse);
  });
}

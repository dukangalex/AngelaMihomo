import 'dart:math' as math;

import 'package:angelamihomo/common/app_localizations.dart';
import 'package:angelamihomo/enum/enum.dart';

import 'common.dart';
import 'profile.dart';

double? _usageRatio(int used, int total) =>
    total > 0 ? (used / total).clamp(0.0, 1.0) : null;

/// Lucian UX/UI Prompt #299 · MIT License
///
/// Warning level of a usage meter as its fill approaches the
/// limit, thresholds from the #299 spec (angela-uxui): at 80% the
/// bar turns warning orange (#F59E0B), at 100% it turns limit red
/// (#E11D48). The colours themselves live with the bar widget.
enum UsageWarningLevel { normal, warning, critical }

UsageWarningLevel usageWarningLevel(double ratio) {
  if (ratio >= 1) return UsageWarningLevel.critical;
  if (ratio >= 0.8) return UsageWarningLevel.warning;
  return UsageWarningLevel.normal;
}

/// Urgency of a subscription's remaining days, for the home
/// readouts (T334 batch 2, frozen design rule): more than 30 days
/// reads as a plain fact, 30 days or fewer earns a reminder tone,
/// and the final week is a warning. The colours live with the
/// widgets; this is the single threshold table they all read.
enum ExpiryWarningLevel { normal, reminder, warning }

ExpiryWarningLevel expiryWarningLevel(int daysLeft) {
  if (daysLeft <= 7) return ExpiryWarningLevel.warning;
  if (daysLeft <= 30) return ExpiryWarningLevel.reminder;
  return ExpiryWarningLevel.normal;
}

int _usedBytes(SubscriptionInfo info) => info.upload + info.download;

class ProfileUsage {
  static const _maxSegments = 4;

  final List<MapEntry<String, SubscriptionInfo>> items;
  final List<MapEntry<String, SubscriptionInfo>> shown;
  final List<SubscriptionInfo> rest;

  const ProfileUsage._(this.items, this.shown, this.rest);

  static ProfileUsage? of(Profile profile) {
    final items = profile.subscriptionUsages;
    if (items.isEmpty) return null;
    final shown = items.topByUsage(
      items.length > _maxSegments ? _maxSegments - 1 : items.length,
    );
    return ProfileUsage._(items, shown, [
      for (final item in items)
        if (!shown.contains(item)) item.value,
    ]);
  }

  bool get isMulti => items.length > 1;

  int get used => items.fold(0, (sum, item) => sum + _usedBytes(item.value));

  int get total => items.fold(0, (sum, item) => sum + item.value.total);

  bool get unlimited => items.any((item) => item.value.total <= 0);

  double? get ratio => unlimited ? null : _usageRatio(used, total);

  String get totalText => unlimited ? '∞' : TrafficValue(value: total).show;

  String get usageText => '${TrafficValue(value: used).show} / $totalText';

  List<double> get segments {
    final limited = rest.where((info) => info.total > 0);
    return [
      for (final item in shown)
        ?_usageRatio(_usedBytes(item.value), item.value.total),
      if (limited.isNotEmpty)
        ?_usageRatio(
          limited.fold(0, (sum, info) => sum + _usedBytes(info)),
          limited.fold(0, (sum, info) => sum + info.total),
        ),
    ];
  }

  /// The single source the home card's expiry date and traffic
  /// figures describe (T223): the earliest expiring source, falling
  /// back to the first source when none carries an expiry. The date
  /// and the traffic must always come from this one source — never
  /// the date from one source and the traffic from an aggregate.
  MapEntry<String, SubscriptionInfo> get primaryEntry {
    MapEntry<String, SubscriptionInfo>? earliest;
    for (final item in items) {
      if (item.value.expire <= 0) continue;
      if (earliest == null || item.value.expire < earliest.value.expire) {
        earliest = item;
      }
    }
    return earliest ?? items.first;
  }

  SubscriptionInfo get _nearest => primaryEntry.value;

  /// Name of [primaryEntry]'s source, shown beside the expiry on the
  /// home card of a merged profile so the date is attributable to the
  /// subscription it belongs to. Null for single-source profiles: the
  /// source is the profile itself, already named by the card title.
  String? get primarySourceName => isMulti ? primaryEntry.key : null;

  int get primaryUsed => _usedBytes(primaryEntry.value);

  int get primaryTotal => primaryEntry.value.total;

  bool get primaryUnlimited => primaryTotal <= 0;

  String get primaryTotalText =>
      primaryUnlimited ? '∞' : TrafficValue(value: primaryTotal).show;

  String get primaryUsageText =>
      '${TrafficValue(value: primaryUsed).show} / $primaryTotalText';

  /// Traffic figure displayed beside the expiry on the home card.
  /// For merged profiles this is [primaryEntry]'s figure, the same
  /// source [expireText] refers to; single-source profiles keep the
  /// (identical) aggregate figure.
  String get cardUsageText => isMulti ? primaryUsageText : usageText;

  String? get expireText => _nearest.expireDesc;

  DateTime? get expireAt {
    final expire = _nearest.expire;
    return expire > 0
        ? DateTime.fromMillisecondsSinceEpoch(expire * 1000)
        : null;
  }

  int? get remaining => unlimited ? null : math.max(total - used, 0);

  int? get daysLeft {
    final expire = _nearest.expire;
    if (expire <= 0) return null;
    final end = DateTime.fromMillisecondsSinceEpoch(expire * 1000);
    return math.max(end.difference(DateTime.now()).inDays, 0);
  }

  bool get isExpired {
    final expire = _nearest.expire;
    return expire > 0 && expire * 1000 < DateTime.now().millisecondsSinceEpoch;
  }

  String get breakdown => [
    for (final item in shown)
      '${item.key} ${switch (_usageRatio(_usedBytes(item.value), item.value.total)) {
        final ratio? => '${(ratio * 100).round()}%',
        null => TrafficValue(value: _usedBytes(item.value)).shortShow,
      }}',
    if (rest.isNotEmpty) '+${rest.length}',
  ].join('  ·  ');
}

extension ProfileUsageExt on Profile {
  String? usageExpireText(ProfileUsage? usage) =>
      usage?.expireText ??
      (type == ProfileType.file ? appLocalizations.localFile : null);
}

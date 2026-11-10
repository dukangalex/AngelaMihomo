// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionInfo _$SubscriptionInfoFromJson(Map<String, dynamic> json) =>
    _SubscriptionInfo(
      upload: (json['upload'] as num?)?.toInt() ?? 0,
      download: (json['download'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      expire: (json['expire'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SubscriptionInfoToJson(_SubscriptionInfo instance) =>
    <String, dynamic>{
      'upload': instance.upload,
      'download': instance.download,
      'total': instance.total,
      'expire': instance.expire,
    };

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String,
  label: json['label'] as String?,
  currentGroupName: json['currentGroupName'] as String?,
  url: json['url'] as String? ?? '',
  lastUpdateDate: json['lastUpdateDate'] == null
      ? null
      : DateTime.parse(json['lastUpdateDate'] as String),
  autoUpdateDuration: Duration(
    microseconds: (json['autoUpdateDuration'] as num).toInt(),
  ),
  subscriptionInfo: json['subscriptionInfo'] == null
      ? null
      : SubscriptionInfo.fromJson(
          json['subscriptionInfo'] as Map<String, dynamic>,
        ),
  autoUpdate: json['autoUpdate'] as bool? ?? true,
  selectedMap:
      (json['selectedMap'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  unfoldSet:
      (json['unfoldSet'] as List<dynamic>?)?.map((e) => e as String).toSet() ??
      const {},
  overrideData: json['overrideData'] == null
      ? const OverrideData()
      : OverrideData.fromJson(json['overrideData'] as Map<String, dynamic>),
  useScriptOverride: json['useScriptOverride'] as bool? ?? false,
  scriptId: json['scriptId'] as String?,
  ageSecretKey: json['ageSecretKey'] as String?,
  groupSwitches:
      (json['group-switches'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const {},
  groupOverrides:
      (json['group-overrides'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, ProxyGroupOverride.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'currentGroupName': instance.currentGroupName,
  'url': instance.url,
  'lastUpdateDate': instance.lastUpdateDate?.toIso8601String(),
  'autoUpdateDuration': instance.autoUpdateDuration.inMicroseconds,
  'subscriptionInfo': instance.subscriptionInfo,
  'autoUpdate': instance.autoUpdate,
  'selectedMap': instance.selectedMap,
  'unfoldSet': instance.unfoldSet.toList(),
  'overrideData': instance.overrideData,
  'useScriptOverride': instance.useScriptOverride,
  'scriptId': instance.scriptId,
  'ageSecretKey': instance.ageSecretKey,
  'group-switches': instance.groupSwitches,
  'group-overrides': instance.groupOverrides,
};

_OverrideData _$OverrideDataFromJson(Map<String, dynamic> json) =>
    _OverrideData(
      enable: json['enable'] as bool? ?? false,
      rule: json['rule'] == null
          ? const OverrideRule()
          : OverrideRule.fromJson(json['rule'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OverrideDataToJson(_OverrideData instance) =>
    <String, dynamic>{'enable': instance.enable, 'rule': instance.rule};

_OverrideRule _$OverrideRuleFromJson(Map<String, dynamic> json) =>
    _OverrideRule(
      type:
          $enumDecodeNullable(_$OverrideRuleTypeEnumMap, json['type']) ??
          OverrideRuleType.added,
      overrideRules:
          (json['overrideRules'] as List<dynamic>?)
              ?.map((e) => Rule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      addedRules:
          (json['addedRules'] as List<dynamic>?)
              ?.map((e) => Rule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$OverrideRuleToJson(_OverrideRule instance) =>
    <String, dynamic>{
      'type': _$OverrideRuleTypeEnumMap[instance.type]!,
      'overrideRules': instance.overrideRules,
      'addedRules': instance.addedRules,
    };

const _$OverrideRuleTypeEnumMap = {
  OverrideRuleType.override: 'override',
  OverrideRuleType.added: 'added',
};

_ProxyGroupOverride _$ProxyGroupOverrideFromJson(Map<String, dynamic> json) =>
    _ProxyGroupOverride(
      url: json['url'] as String?,
      interval: (json['interval'] as num?)?.toInt(),
      lazy: json['lazy'] as bool?,
      timeout: (json['timeout'] as num?)?.toInt(),
      maxFailedTimes: (json['max-failed-times'] as num?)?.toInt(),
      filter: json['filter'] as String?,
      excludeFilter: json['exclude-filter'] as String?,
      excludeType: json['exclude-type'] as String?,
      expectedStatus: json['expected-status'] as String?,
      hidden: json['hidden'] as bool?,
      icon: json['icon'] as String?,
      tolerance: (json['tolerance'] as num?)?.toInt(),
      defaultSelected: json['default-selected'] as String?,
      emptyFallback: json['empty-fallback'] as String?,
      disableUdp: json['disable-udp'] as bool?,
      includeAll: json['include-all'] as bool?,
      includeAllProxies: json['include-all-proxies'] as bool?,
      includeAllProviders: json['include-all-providers'] as bool?,
      strategy: json['strategy'] as String?,
    );

Map<String, dynamic> _$ProxyGroupOverrideToJson(_ProxyGroupOverride instance) =>
    <String, dynamic>{
      'url': ?instance.url,
      'interval': ?instance.interval,
      'lazy': ?instance.lazy,
      'timeout': ?instance.timeout,
      'max-failed-times': ?instance.maxFailedTimes,
      'filter': ?instance.filter,
      'exclude-filter': ?instance.excludeFilter,
      'exclude-type': ?instance.excludeType,
      'expected-status': ?instance.expectedStatus,
      'hidden': ?instance.hidden,
      'icon': ?instance.icon,
      'tolerance': ?instance.tolerance,
      'default-selected': ?instance.defaultSelected,
      'empty-fallback': ?instance.emptyFallback,
      'disable-udp': ?instance.disableUdp,
      'include-all': ?instance.includeAll,
      'include-all-proxies': ?instance.includeAllProxies,
      'include-all-providers': ?instance.includeAllProviders,
      'strategy': ?instance.strategy,
    };

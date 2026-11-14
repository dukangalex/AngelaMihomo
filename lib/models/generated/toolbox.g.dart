// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../toolbox.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DnsQueryRecord _$DnsQueryRecordFromJson(Map<String, dynamic> json) =>
    _DnsQueryRecord(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      ttl: (json['ttl'] as num?)?.toInt() ?? 0,
      data: json['data'] as String? ?? '',
    );

Map<String, dynamic> _$DnsQueryRecordToJson(_DnsQueryRecord instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'ttl': instance.ttl,
      'data': instance.data,
    };

_DnsQueryResult _$DnsQueryResultFromJson(Map<String, dynamic> json) =>
    _DnsQueryResult(
      domain: json['domain'] as String? ?? '',
      type: json['type'] as String? ?? 'A',
      mode: json['mode'] as String? ?? '',
      server: json['server'] as String? ?? '',
      rcode: json['rcode'] as String? ?? '',
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map((e) => DnsQueryRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      elapsed: (json['elapsed'] as num?)?.toDouble() ?? 0,
      route: json['route'] as String? ?? '',
      hosts:
          (json['hosts'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      fakeIpRange: json['fake-ip-range'] as String? ?? '',
      filterMode: json['filter-mode'] as String? ?? '',
      outbound: json['outbound'] as String? ?? '',
      outboundType: json['outbound-type'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$DnsQueryResultToJson(_DnsQueryResult instance) =>
    <String, dynamic>{
      'domain': instance.domain,
      'type': instance.type,
      'mode': instance.mode,
      'server': instance.server,
      'rcode': instance.rcode,
      'answers': instance.answers,
      'elapsed': instance.elapsed,
      'route': instance.route,
      'hosts': instance.hosts,
      'fake-ip-range': instance.fakeIpRange,
      'filter-mode': instance.filterMode,
      'outbound': instance.outbound,
      'outbound-type': instance.outboundType,
      'error': instance.error,
    };

_AgeCryptResult _$AgeCryptResultFromJson(Map<String, dynamic> json) =>
    _AgeCryptResult(
      data: json['data'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );

Map<String, dynamic> _$AgeCryptResultToJson(_AgeCryptResult instance) =>
    <String, dynamic>{'data': instance.data, 'error': instance.error};

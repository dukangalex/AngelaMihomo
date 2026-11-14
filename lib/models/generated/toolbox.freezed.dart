// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../toolbox.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DnsQueryRecord {

 String get name; String get type; int get ttl; String get data;
/// Create a copy of DnsQueryRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DnsQueryRecordCopyWith<DnsQueryRecord> get copyWith => _$DnsQueryRecordCopyWithImpl<DnsQueryRecord>(this as DnsQueryRecord, _$identity);

  /// Serializes this DnsQueryRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DnsQueryRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DnsQueryRecord&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.ttl, _this.ttl) || other.ttl == _this.ttl)&&(identical(other.data, _this.data) || other.data == _this.data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DnsQueryRecord;
  return Object.hash(runtimeType,_this.name,_this.type,_this.ttl,_this.data);
}

@override
String toString() {
  final _this = this as DnsQueryRecord;
  return 'DnsQueryRecord(name: ${_this.name}, type: ${_this.type}, ttl: ${_this.ttl}, data: ${_this.data})';
}


}

/// @nodoc
abstract mixin class $DnsQueryRecordCopyWith<$Res>  {
  factory $DnsQueryRecordCopyWith(DnsQueryRecord value, $Res Function(DnsQueryRecord) _then) = _$DnsQueryRecordCopyWithImpl;
@useResult
$Res call({
 String name, String type, int ttl, String data
});




}
/// @nodoc
class _$DnsQueryRecordCopyWithImpl<$Res>
    implements $DnsQueryRecordCopyWith<$Res> {
  _$DnsQueryRecordCopyWithImpl(this._self, this._then);

  final DnsQueryRecord _self;
  final $Res Function(DnsQueryRecord) _then;

/// Create a copy of DnsQueryRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? type = null,Object? ttl = null,Object? data = null,}) {
  return _then(DnsQueryRecord(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,ttl: null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DnsQueryRecord].
extension DnsQueryRecordPatterns on DnsQueryRecord {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DnsQueryRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DnsQueryRecord() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DnsQueryRecord value)  $default,){
final _that = this;
switch (_that) {
case _DnsQueryRecord():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DnsQueryRecord value)?  $default,){
final _that = this;
switch (_that) {
case _DnsQueryRecord() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String type,  int ttl,  String data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DnsQueryRecord() when $default != null:
return $default(_that.name,_that.type,_that.ttl,_that.data);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String type,  int ttl,  String data)  $default,) {final _that = this;
switch (_that) {
case _DnsQueryRecord():
return $default(_that.name,_that.type,_that.ttl,_that.data);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String type,  int ttl,  String data)?  $default,) {final _that = this;
switch (_that) {
case _DnsQueryRecord() when $default != null:
return $default(_that.name,_that.type,_that.ttl,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DnsQueryRecord implements DnsQueryRecord {
  const _DnsQueryRecord({this.name = '', this.type = '', this.ttl = 0, this.data = ''});
  factory _DnsQueryRecord.fromJson(Map<String, dynamic> json) => _$DnsQueryRecordFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String type;
@override@JsonKey() final  int ttl;
@override@JsonKey() final  String data;

/// Create a copy of DnsQueryRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DnsQueryRecordCopyWith<_DnsQueryRecord> get copyWith => __$DnsQueryRecordCopyWithImpl<_DnsQueryRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DnsQueryRecordToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DnsQueryRecord&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.ttl, ttl) || other.ttl == ttl)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,type,ttl,data);
}

@override
String toString() {
    return 'DnsQueryRecord(name: $name, type: $type, ttl: $ttl, data: $data)';
}


}

/// @nodoc
abstract mixin class _$DnsQueryRecordCopyWith<$Res> implements $DnsQueryRecordCopyWith<$Res> {
  factory _$DnsQueryRecordCopyWith(_DnsQueryRecord value, $Res Function(_DnsQueryRecord) _then) = __$DnsQueryRecordCopyWithImpl;
@override @useResult
$Res call({
 String name, String type, int ttl, String data
});




}
/// @nodoc
class __$DnsQueryRecordCopyWithImpl<$Res>
    implements _$DnsQueryRecordCopyWith<$Res> {
  __$DnsQueryRecordCopyWithImpl(this._self, this._then);

  final _DnsQueryRecord _self;
  final $Res Function(_DnsQueryRecord) _then;

/// Create a copy of DnsQueryRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? type = null,Object? ttl = null,Object? data = null,}) {
  return _then(_DnsQueryRecord(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,ttl: null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as int,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DnsQueryResult {

 String get domain; String get type; String get mode; String get server; String get rcode; List<DnsQueryRecord> get answers; double get elapsed; String get route; List<String> get hosts;@JsonKey(name: 'fake-ip-range') String get fakeIpRange;@JsonKey(name: 'filter-mode') String get filterMode; String get outbound;@JsonKey(name: 'outbound-type') String get outboundType; String get error;
/// Create a copy of DnsQueryResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DnsQueryResultCopyWith<DnsQueryResult> get copyWith => _$DnsQueryResultCopyWithImpl<DnsQueryResult>(this as DnsQueryResult, _$identity);

  /// Serializes this DnsQueryResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DnsQueryResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DnsQueryResult&&(identical(other.domain, _this.domain) || other.domain == _this.domain)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.server, _this.server) || other.server == _this.server)&&(identical(other.rcode, _this.rcode) || other.rcode == _this.rcode)&&const DeepCollectionEquality().equals(other.answers, _this.answers)&&(identical(other.elapsed, _this.elapsed) || other.elapsed == _this.elapsed)&&(identical(other.route, _this.route) || other.route == _this.route)&&const DeepCollectionEquality().equals(other.hosts, _this.hosts)&&(identical(other.fakeIpRange, _this.fakeIpRange) || other.fakeIpRange == _this.fakeIpRange)&&(identical(other.filterMode, _this.filterMode) || other.filterMode == _this.filterMode)&&(identical(other.outbound, _this.outbound) || other.outbound == _this.outbound)&&(identical(other.outboundType, _this.outboundType) || other.outboundType == _this.outboundType)&&(identical(other.error, _this.error) || other.error == _this.error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DnsQueryResult;
  return Object.hash(runtimeType,_this.domain,_this.type,_this.mode,_this.server,_this.rcode,const DeepCollectionEquality().hash(_this.answers),_this.elapsed,_this.route,const DeepCollectionEquality().hash(_this.hosts),_this.fakeIpRange,_this.filterMode,_this.outbound,_this.outboundType,_this.error);
}

@override
String toString() {
  final _this = this as DnsQueryResult;
  return 'DnsQueryResult(domain: ${_this.domain}, type: ${_this.type}, mode: ${_this.mode}, server: ${_this.server}, rcode: ${_this.rcode}, answers: ${_this.answers}, elapsed: ${_this.elapsed}, route: ${_this.route}, hosts: ${_this.hosts}, fakeIpRange: ${_this.fakeIpRange}, filterMode: ${_this.filterMode}, outbound: ${_this.outbound}, outboundType: ${_this.outboundType}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $DnsQueryResultCopyWith<$Res>  {
  factory $DnsQueryResultCopyWith(DnsQueryResult value, $Res Function(DnsQueryResult) _then) = _$DnsQueryResultCopyWithImpl;
@useResult
$Res call({
 String domain, String type, String mode, String server, String rcode, List<DnsQueryRecord> answers, double elapsed, String route, List<String> hosts,@JsonKey(name: 'fake-ip-range') String fakeIpRange,@JsonKey(name: 'filter-mode') String filterMode, String outbound,@JsonKey(name: 'outbound-type') String outboundType, String error
});




}
/// @nodoc
class _$DnsQueryResultCopyWithImpl<$Res>
    implements $DnsQueryResultCopyWith<$Res> {
  _$DnsQueryResultCopyWithImpl(this._self, this._then);

  final DnsQueryResult _self;
  final $Res Function(DnsQueryResult) _then;

/// Create a copy of DnsQueryResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? domain = null,Object? type = null,Object? mode = null,Object? server = null,Object? rcode = null,Object? answers = null,Object? elapsed = null,Object? route = null,Object? hosts = null,Object? fakeIpRange = null,Object? filterMode = null,Object? outbound = null,Object? outboundType = null,Object? error = null,}) {
  return _then(DnsQueryResult(
domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as String,rcode: null == rcode ? _self.rcode : rcode // ignore: cast_nullable_to_non_nullable
as String,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as List<DnsQueryRecord>,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,hosts: null == hosts ? _self.hosts : hosts // ignore: cast_nullable_to_non_nullable
as List<String>,fakeIpRange: null == fakeIpRange ? _self.fakeIpRange : fakeIpRange // ignore: cast_nullable_to_non_nullable
as String,filterMode: null == filterMode ? _self.filterMode : filterMode // ignore: cast_nullable_to_non_nullable
as String,outbound: null == outbound ? _self.outbound : outbound // ignore: cast_nullable_to_non_nullable
as String,outboundType: null == outboundType ? _self.outboundType : outboundType // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DnsQueryResult].
extension DnsQueryResultPatterns on DnsQueryResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DnsQueryResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DnsQueryResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DnsQueryResult value)  $default,){
final _that = this;
switch (_that) {
case _DnsQueryResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DnsQueryResult value)?  $default,){
final _that = this;
switch (_that) {
case _DnsQueryResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String domain,  String type,  String mode,  String server,  String rcode,  List<DnsQueryRecord> answers,  double elapsed,  String route,  List<String> hosts, @JsonKey(name: 'fake-ip-range')  String fakeIpRange, @JsonKey(name: 'filter-mode')  String filterMode,  String outbound, @JsonKey(name: 'outbound-type')  String outboundType,  String error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DnsQueryResult() when $default != null:
return $default(_that.domain,_that.type,_that.mode,_that.server,_that.rcode,_that.answers,_that.elapsed,_that.route,_that.hosts,_that.fakeIpRange,_that.filterMode,_that.outbound,_that.outboundType,_that.error);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String domain,  String type,  String mode,  String server,  String rcode,  List<DnsQueryRecord> answers,  double elapsed,  String route,  List<String> hosts, @JsonKey(name: 'fake-ip-range')  String fakeIpRange, @JsonKey(name: 'filter-mode')  String filterMode,  String outbound, @JsonKey(name: 'outbound-type')  String outboundType,  String error)  $default,) {final _that = this;
switch (_that) {
case _DnsQueryResult():
return $default(_that.domain,_that.type,_that.mode,_that.server,_that.rcode,_that.answers,_that.elapsed,_that.route,_that.hosts,_that.fakeIpRange,_that.filterMode,_that.outbound,_that.outboundType,_that.error);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String domain,  String type,  String mode,  String server,  String rcode,  List<DnsQueryRecord> answers,  double elapsed,  String route,  List<String> hosts, @JsonKey(name: 'fake-ip-range')  String fakeIpRange, @JsonKey(name: 'filter-mode')  String filterMode,  String outbound, @JsonKey(name: 'outbound-type')  String outboundType,  String error)?  $default,) {final _that = this;
switch (_that) {
case _DnsQueryResult() when $default != null:
return $default(_that.domain,_that.type,_that.mode,_that.server,_that.rcode,_that.answers,_that.elapsed,_that.route,_that.hosts,_that.fakeIpRange,_that.filterMode,_that.outbound,_that.outboundType,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DnsQueryResult implements DnsQueryResult {
  const _DnsQueryResult({this.domain = '', this.type = 'A', this.mode = '', this.server = '', this.rcode = '',  List<DnsQueryRecord> answers = const [], this.elapsed = 0, this.route = '',  List<String> hosts = const [], @JsonKey(name: 'fake-ip-range') this.fakeIpRange = '', @JsonKey(name: 'filter-mode') this.filterMode = '', this.outbound = '', @JsonKey(name: 'outbound-type') this.outboundType = '', this.error = ''}): _answers = answers,_hosts = hosts;
  factory _DnsQueryResult.fromJson(Map<String, dynamic> json) => _$DnsQueryResultFromJson(json);

@override@JsonKey() final  String domain;
@override@JsonKey() final  String type;
@override@JsonKey() final  String mode;
@override@JsonKey() final  String server;
@override@JsonKey() final  String rcode;
 final  List<DnsQueryRecord> _answers;
@override@JsonKey() List<DnsQueryRecord> get answers {
  if (_answers is EqualUnmodifiableListView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answers);
}

@override@JsonKey() final  double elapsed;
@override@JsonKey() final  String route;
 final  List<String> _hosts;
@override@JsonKey() List<String> get hosts {
  if (_hosts is EqualUnmodifiableListView) return _hosts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hosts);
}

@override@JsonKey(name: 'fake-ip-range') final  String fakeIpRange;
@override@JsonKey(name: 'filter-mode') final  String filterMode;
@override@JsonKey() final  String outbound;
@override@JsonKey(name: 'outbound-type') final  String outboundType;
@override@JsonKey() final  String error;

/// Create a copy of DnsQueryResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DnsQueryResultCopyWith<_DnsQueryResult> get copyWith => __$DnsQueryResultCopyWithImpl<_DnsQueryResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DnsQueryResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DnsQueryResult&&(identical(other.domain, domain) || other.domain == domain)&&(identical(other.type, type) || other.type == type)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.server, server) || other.server == server)&&(identical(other.rcode, rcode) || other.rcode == rcode)&&const DeepCollectionEquality().equals(other.answers, _answers)&&(identical(other.elapsed, elapsed) || other.elapsed == elapsed)&&(identical(other.route, route) || other.route == route)&&const DeepCollectionEquality().equals(other.hosts, _hosts)&&(identical(other.fakeIpRange, fakeIpRange) || other.fakeIpRange == fakeIpRange)&&(identical(other.filterMode, filterMode) || other.filterMode == filterMode)&&(identical(other.outbound, outbound) || other.outbound == outbound)&&(identical(other.outboundType, outboundType) || other.outboundType == outboundType)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,domain,type,mode,server,rcode,const DeepCollectionEquality().hash(_answers),elapsed,route,const DeepCollectionEquality().hash(_hosts),fakeIpRange,filterMode,outbound,outboundType,error);
}

@override
String toString() {
    return 'DnsQueryResult(domain: $domain, type: $type, mode: $mode, server: $server, rcode: $rcode, answers: $answers, elapsed: $elapsed, route: $route, hosts: $hosts, fakeIpRange: $fakeIpRange, filterMode: $filterMode, outbound: $outbound, outboundType: $outboundType, error: $error)';
}


}

/// @nodoc
abstract mixin class _$DnsQueryResultCopyWith<$Res> implements $DnsQueryResultCopyWith<$Res> {
  factory _$DnsQueryResultCopyWith(_DnsQueryResult value, $Res Function(_DnsQueryResult) _then) = __$DnsQueryResultCopyWithImpl;
@override @useResult
$Res call({
 String domain, String type, String mode, String server, String rcode, List<DnsQueryRecord> answers, double elapsed, String route, List<String> hosts,@JsonKey(name: 'fake-ip-range') String fakeIpRange,@JsonKey(name: 'filter-mode') String filterMode, String outbound,@JsonKey(name: 'outbound-type') String outboundType, String error
});




}
/// @nodoc
class __$DnsQueryResultCopyWithImpl<$Res>
    implements _$DnsQueryResultCopyWith<$Res> {
  __$DnsQueryResultCopyWithImpl(this._self, this._then);

  final _DnsQueryResult _self;
  final $Res Function(_DnsQueryResult) _then;

/// Create a copy of DnsQueryResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? domain = null,Object? type = null,Object? mode = null,Object? server = null,Object? rcode = null,Object? answers = null,Object? elapsed = null,Object? route = null,Object? hosts = null,Object? fakeIpRange = null,Object? filterMode = null,Object? outbound = null,Object? outboundType = null,Object? error = null,}) {
  return _then(_DnsQueryResult(
domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as String,rcode: null == rcode ? _self.rcode : rcode // ignore: cast_nullable_to_non_nullable
as String,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as List<DnsQueryRecord>,elapsed: null == elapsed ? _self.elapsed : elapsed // ignore: cast_nullable_to_non_nullable
as double,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,hosts: null == hosts ? _self._hosts : hosts // ignore: cast_nullable_to_non_nullable
as List<String>,fakeIpRange: null == fakeIpRange ? _self.fakeIpRange : fakeIpRange // ignore: cast_nullable_to_non_nullable
as String,filterMode: null == filterMode ? _self.filterMode : filterMode // ignore: cast_nullable_to_non_nullable
as String,outbound: null == outbound ? _self.outbound : outbound // ignore: cast_nullable_to_non_nullable
as String,outboundType: null == outboundType ? _self.outboundType : outboundType // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AgeCryptResult {

 String get data; String get error;
/// Create a copy of AgeCryptResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgeCryptResultCopyWith<AgeCryptResult> get copyWith => _$AgeCryptResultCopyWithImpl<AgeCryptResult>(this as AgeCryptResult, _$identity);

  /// Serializes this AgeCryptResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AgeCryptResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgeCryptResult&&(identical(other.data, _this.data) || other.data == _this.data)&&(identical(other.error, _this.error) || other.error == _this.error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AgeCryptResult;
  return Object.hash(runtimeType,_this.data,_this.error);
}

@override
String toString() {
  final _this = this as AgeCryptResult;
  return 'AgeCryptResult(data: ${_this.data}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $AgeCryptResultCopyWith<$Res>  {
  factory $AgeCryptResultCopyWith(AgeCryptResult value, $Res Function(AgeCryptResult) _then) = _$AgeCryptResultCopyWithImpl;
@useResult
$Res call({
 String data, String error
});




}
/// @nodoc
class _$AgeCryptResultCopyWithImpl<$Res>
    implements $AgeCryptResultCopyWith<$Res> {
  _$AgeCryptResultCopyWithImpl(this._self, this._then);

  final AgeCryptResult _self;
  final $Res Function(AgeCryptResult) _then;

/// Create a copy of AgeCryptResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? error = null,}) {
  return _then(AgeCryptResult(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AgeCryptResult].
extension AgeCryptResultPatterns on AgeCryptResult {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgeCryptResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgeCryptResult() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgeCryptResult value)  $default,){
final _that = this;
switch (_that) {
case _AgeCryptResult():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgeCryptResult value)?  $default,){
final _that = this;
switch (_that) {
case _AgeCryptResult() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String data,  String error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgeCryptResult() when $default != null:
return $default(_that.data,_that.error);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String data,  String error)  $default,) {final _that = this;
switch (_that) {
case _AgeCryptResult():
return $default(_that.data,_that.error);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String data,  String error)?  $default,) {final _that = this;
switch (_that) {
case _AgeCryptResult() when $default != null:
return $default(_that.data,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgeCryptResult implements AgeCryptResult {
  const _AgeCryptResult({this.data = '', this.error = ''});
  factory _AgeCryptResult.fromJson(Map<String, dynamic> json) => _$AgeCryptResultFromJson(json);

@override@JsonKey() final  String data;
@override@JsonKey() final  String error;

/// Create a copy of AgeCryptResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgeCryptResultCopyWith<_AgeCryptResult> get copyWith => __$AgeCryptResultCopyWithImpl<_AgeCryptResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgeCryptResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgeCryptResult&&(identical(other.data, data) || other.data == data)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,data,error);
}

@override
String toString() {
    return 'AgeCryptResult(data: $data, error: $error)';
}


}

/// @nodoc
abstract mixin class _$AgeCryptResultCopyWith<$Res> implements $AgeCryptResultCopyWith<$Res> {
  factory _$AgeCryptResultCopyWith(_AgeCryptResult value, $Res Function(_AgeCryptResult) _then) = __$AgeCryptResultCopyWithImpl;
@override @useResult
$Res call({
 String data, String error
});




}
/// @nodoc
class __$AgeCryptResultCopyWithImpl<$Res>
    implements _$AgeCryptResultCopyWith<$Res> {
  __$AgeCryptResultCopyWithImpl(this._self, this._then);

  final _AgeCryptResult _self;
  final $Res Function(_AgeCryptResult) _then;

/// Create a copy of AgeCryptResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? error = null,}) {
  return _then(_AgeCryptResult(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

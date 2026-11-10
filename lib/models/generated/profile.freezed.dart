// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of '../profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionInfo {

 int get upload; int get download; int get total; int get expire;
/// Create a copy of SubscriptionInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionInfoCopyWith<SubscriptionInfo> get copyWith => _$SubscriptionInfoCopyWithImpl<SubscriptionInfo>(this as SubscriptionInfo, _$identity);

  /// Serializes this SubscriptionInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubscriptionInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionInfo&&(identical(other.upload, _this.upload) || other.upload == _this.upload)&&(identical(other.download, _this.download) || other.download == _this.download)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.expire, _this.expire) || other.expire == _this.expire));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubscriptionInfo;
  return Object.hash(runtimeType,_this.upload,_this.download,_this.total,_this.expire);
}

@override
String toString() {
  final _this = this as SubscriptionInfo;
  return 'SubscriptionInfo(upload: ${_this.upload}, download: ${_this.download}, total: ${_this.total}, expire: ${_this.expire})';
}


}

/// @nodoc
abstract mixin class $SubscriptionInfoCopyWith<$Res>  {
  factory $SubscriptionInfoCopyWith(SubscriptionInfo value, $Res Function(SubscriptionInfo) _then) = _$SubscriptionInfoCopyWithImpl;
@useResult
$Res call({
 int upload, int download, int total, int expire
});




}
/// @nodoc
class _$SubscriptionInfoCopyWithImpl<$Res>
    implements $SubscriptionInfoCopyWith<$Res> {
  _$SubscriptionInfoCopyWithImpl(this._self, this._then);

  final SubscriptionInfo _self;
  final $Res Function(SubscriptionInfo) _then;

/// Create a copy of SubscriptionInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? upload = null,Object? download = null,Object? total = null,Object? expire = null,}) {
  return _then(SubscriptionInfo(
upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,expire: null == expire ? _self.expire : expire // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionInfo].
extension SubscriptionInfoPatterns on SubscriptionInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionInfo value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int upload,  int download,  int total,  int expire)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionInfo() when $default != null:
return $default(_that.upload,_that.download,_that.total,_that.expire);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int upload,  int download,  int total,  int expire)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionInfo():
return $default(_that.upload,_that.download,_that.total,_that.expire);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int upload,  int download,  int total,  int expire)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionInfo() when $default != null:
return $default(_that.upload,_that.download,_that.total,_that.expire);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionInfo implements SubscriptionInfo {
  const _SubscriptionInfo({this.upload = 0, this.download = 0, this.total = 0, this.expire = 0});
  factory _SubscriptionInfo.fromJson(Map<String, dynamic> json) => _$SubscriptionInfoFromJson(json);

@override@JsonKey() final  int upload;
@override@JsonKey() final  int download;
@override@JsonKey() final  int total;
@override@JsonKey() final  int expire;

/// Create a copy of SubscriptionInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionInfoCopyWith<_SubscriptionInfo> get copyWith => __$SubscriptionInfoCopyWithImpl<_SubscriptionInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionInfo&&(identical(other.upload, upload) || other.upload == upload)&&(identical(other.download, download) || other.download == download)&&(identical(other.total, total) || other.total == total)&&(identical(other.expire, expire) || other.expire == expire));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,upload,download,total,expire);
}

@override
String toString() {
    return 'SubscriptionInfo(upload: $upload, download: $download, total: $total, expire: $expire)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionInfoCopyWith<$Res> implements $SubscriptionInfoCopyWith<$Res> {
  factory _$SubscriptionInfoCopyWith(_SubscriptionInfo value, $Res Function(_SubscriptionInfo) _then) = __$SubscriptionInfoCopyWithImpl;
@override @useResult
$Res call({
 int upload, int download, int total, int expire
});




}
/// @nodoc
class __$SubscriptionInfoCopyWithImpl<$Res>
    implements _$SubscriptionInfoCopyWith<$Res> {
  __$SubscriptionInfoCopyWithImpl(this._self, this._then);

  final _SubscriptionInfo _self;
  final $Res Function(_SubscriptionInfo) _then;

/// Create a copy of SubscriptionInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? upload = null,Object? download = null,Object? total = null,Object? expire = null,}) {
  return _then(_SubscriptionInfo(
upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,expire: null == expire ? _self.expire : expire // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Profile {

 String get id; String? get label; String? get currentGroupName; String get url; DateTime? get lastUpdateDate; Duration get autoUpdateDuration; SubscriptionInfo? get subscriptionInfo; bool get autoUpdate; SelectedMap get selectedMap; Set<String> get unfoldSet; OverrideData get overrideData;@JsonKey(includeToJson: false, includeFromJson: false) bool get isUpdating; bool get useScriptOverride; String? get scriptId; String? get ageSecretKey;@JsonKey(name: 'group-switches') Map<String, bool> get groupSwitches;@JsonKey(name: 'group-overrides') Map<String, ProxyGroupOverride> get groupOverrides;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Profile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.currentGroupName, _this.currentGroupName) || other.currentGroupName == _this.currentGroupName)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.lastUpdateDate, _this.lastUpdateDate) || other.lastUpdateDate == _this.lastUpdateDate)&&(identical(other.autoUpdateDuration, _this.autoUpdateDuration) || other.autoUpdateDuration == _this.autoUpdateDuration)&&(identical(other.subscriptionInfo, _this.subscriptionInfo) || other.subscriptionInfo == _this.subscriptionInfo)&&(identical(other.autoUpdate, _this.autoUpdate) || other.autoUpdate == _this.autoUpdate)&&const DeepCollectionEquality().equals(other.selectedMap, _this.selectedMap)&&const DeepCollectionEquality().equals(other.unfoldSet, _this.unfoldSet)&&(identical(other.overrideData, _this.overrideData) || other.overrideData == _this.overrideData)&&(identical(other.isUpdating, _this.isUpdating) || other.isUpdating == _this.isUpdating)&&(identical(other.useScriptOverride, _this.useScriptOverride) || other.useScriptOverride == _this.useScriptOverride)&&(identical(other.scriptId, _this.scriptId) || other.scriptId == _this.scriptId)&&(identical(other.ageSecretKey, _this.ageSecretKey) || other.ageSecretKey == _this.ageSecretKey)&&const DeepCollectionEquality().equals(other.groupSwitches, _this.groupSwitches)&&const DeepCollectionEquality().equals(other.groupOverrides, _this.groupOverrides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Profile;
  return Object.hash(runtimeType,_this.id,_this.label,_this.currentGroupName,_this.url,_this.lastUpdateDate,_this.autoUpdateDuration,_this.subscriptionInfo,_this.autoUpdate,const DeepCollectionEquality().hash(_this.selectedMap),const DeepCollectionEquality().hash(_this.unfoldSet),_this.overrideData,_this.isUpdating,_this.useScriptOverride,_this.scriptId,_this.ageSecretKey,const DeepCollectionEquality().hash(_this.groupSwitches),const DeepCollectionEquality().hash(_this.groupOverrides));
}

@override
String toString() {
  final _this = this as Profile;
  return 'Profile(id: ${_this.id}, label: ${_this.label}, currentGroupName: ${_this.currentGroupName}, url: ${_this.url}, lastUpdateDate: ${_this.lastUpdateDate}, autoUpdateDuration: ${_this.autoUpdateDuration}, subscriptionInfo: ${_this.subscriptionInfo}, autoUpdate: ${_this.autoUpdate}, selectedMap: ${_this.selectedMap}, unfoldSet: ${_this.unfoldSet}, overrideData: ${_this.overrideData}, isUpdating: ${_this.isUpdating}, useScriptOverride: ${_this.useScriptOverride}, scriptId: ${_this.scriptId}, ageSecretKey: ${_this.ageSecretKey}, groupSwitches: ${_this.groupSwitches}, groupOverrides: ${_this.groupOverrides})';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String id, String? label, String? currentGroupName, String url, DateTime? lastUpdateDate, Duration autoUpdateDuration, SubscriptionInfo? subscriptionInfo, bool autoUpdate, SelectedMap selectedMap, Set<String> unfoldSet, OverrideData overrideData,@JsonKey(includeToJson: false, includeFromJson: false) bool isUpdating, bool useScriptOverride, String? scriptId, String? ageSecretKey,@JsonKey(name: 'group-switches') Map<String, bool> groupSwitches,@JsonKey(name: 'group-overrides') Map<String, ProxyGroupOverride> groupOverrides
});


$SubscriptionInfoCopyWith<$Res>? get subscriptionInfo;$OverrideDataCopyWith<$Res> get overrideData;

}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = freezed,Object? currentGroupName = freezed,Object? url = null,Object? lastUpdateDate = freezed,Object? autoUpdateDuration = null,Object? subscriptionInfo = freezed,Object? autoUpdate = null,Object? selectedMap = null,Object? unfoldSet = null,Object? overrideData = null,Object? isUpdating = null,Object? useScriptOverride = null,Object? scriptId = freezed,Object? ageSecretKey = freezed,Object? groupSwitches = null,Object? groupOverrides = null,}) {
  return _then(Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,currentGroupName: freezed == currentGroupName ? _self.currentGroupName : currentGroupName // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,lastUpdateDate: freezed == lastUpdateDate ? _self.lastUpdateDate : lastUpdateDate // ignore: cast_nullable_to_non_nullable
as DateTime?,autoUpdateDuration: null == autoUpdateDuration ? _self.autoUpdateDuration : autoUpdateDuration // ignore: cast_nullable_to_non_nullable
as Duration,subscriptionInfo: freezed == subscriptionInfo ? _self.subscriptionInfo : subscriptionInfo // ignore: cast_nullable_to_non_nullable
as SubscriptionInfo?,autoUpdate: null == autoUpdate ? _self.autoUpdate : autoUpdate // ignore: cast_nullable_to_non_nullable
as bool,selectedMap: null == selectedMap ? _self.selectedMap : selectedMap // ignore: cast_nullable_to_non_nullable
as SelectedMap,unfoldSet: null == unfoldSet ? _self.unfoldSet : unfoldSet // ignore: cast_nullable_to_non_nullable
as Set<String>,overrideData: null == overrideData ? _self.overrideData : overrideData // ignore: cast_nullable_to_non_nullable
as OverrideData,isUpdating: null == isUpdating ? _self.isUpdating : isUpdating // ignore: cast_nullable_to_non_nullable
as bool,useScriptOverride: null == useScriptOverride ? _self.useScriptOverride : useScriptOverride // ignore: cast_nullable_to_non_nullable
as bool,scriptId: freezed == scriptId ? _self.scriptId : scriptId // ignore: cast_nullable_to_non_nullable
as String?,ageSecretKey: freezed == ageSecretKey ? _self.ageSecretKey : ageSecretKey // ignore: cast_nullable_to_non_nullable
as String?,groupSwitches: null == groupSwitches ? _self.groupSwitches : groupSwitches // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,groupOverrides: null == groupOverrides ? _self.groupOverrides : groupOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, ProxyGroupOverride>,
  ));
}
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionInfoCopyWith<$Res>? get subscriptionInfo {
    if (_self.subscriptionInfo == null) {
    return null;
  }

  return $SubscriptionInfoCopyWith<$Res>(_self.subscriptionInfo!, (value) {
    return _then(_self.copyWith(subscriptionInfo: value));
  });
}/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OverrideDataCopyWith<$Res> get overrideData {
  
  return $OverrideDataCopyWith<$Res>(_self.overrideData, (value) {
    return _then(_self.copyWith(overrideData: value));
  });
}
}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profile value)  $default,){
final _that = this;
switch (_that) {
case _Profile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profile value)?  $default,){
final _that = this;
switch (_that) {
case _Profile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? label,  String? currentGroupName,  String url,  DateTime? lastUpdateDate,  Duration autoUpdateDuration,  SubscriptionInfo? subscriptionInfo,  bool autoUpdate,  SelectedMap selectedMap,  Set<String> unfoldSet,  OverrideData overrideData, @JsonKey(includeToJson: false, includeFromJson: false)  bool isUpdating,  bool useScriptOverride,  String? scriptId,  String? ageSecretKey, @JsonKey(name: 'group-switches')  Map<String, bool> groupSwitches, @JsonKey(name: 'group-overrides')  Map<String, ProxyGroupOverride> groupOverrides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.label,_that.currentGroupName,_that.url,_that.lastUpdateDate,_that.autoUpdateDuration,_that.subscriptionInfo,_that.autoUpdate,_that.selectedMap,_that.unfoldSet,_that.overrideData,_that.isUpdating,_that.useScriptOverride,_that.scriptId,_that.ageSecretKey,_that.groupSwitches,_that.groupOverrides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? label,  String? currentGroupName,  String url,  DateTime? lastUpdateDate,  Duration autoUpdateDuration,  SubscriptionInfo? subscriptionInfo,  bool autoUpdate,  SelectedMap selectedMap,  Set<String> unfoldSet,  OverrideData overrideData, @JsonKey(includeToJson: false, includeFromJson: false)  bool isUpdating,  bool useScriptOverride,  String? scriptId,  String? ageSecretKey, @JsonKey(name: 'group-switches')  Map<String, bool> groupSwitches, @JsonKey(name: 'group-overrides')  Map<String, ProxyGroupOverride> groupOverrides)  $default,) {final _that = this;
switch (_that) {
case _Profile():
return $default(_that.id,_that.label,_that.currentGroupName,_that.url,_that.lastUpdateDate,_that.autoUpdateDuration,_that.subscriptionInfo,_that.autoUpdate,_that.selectedMap,_that.unfoldSet,_that.overrideData,_that.isUpdating,_that.useScriptOverride,_that.scriptId,_that.ageSecretKey,_that.groupSwitches,_that.groupOverrides);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? label,  String? currentGroupName,  String url,  DateTime? lastUpdateDate,  Duration autoUpdateDuration,  SubscriptionInfo? subscriptionInfo,  bool autoUpdate,  SelectedMap selectedMap,  Set<String> unfoldSet,  OverrideData overrideData, @JsonKey(includeToJson: false, includeFromJson: false)  bool isUpdating,  bool useScriptOverride,  String? scriptId,  String? ageSecretKey, @JsonKey(name: 'group-switches')  Map<String, bool> groupSwitches, @JsonKey(name: 'group-overrides')  Map<String, ProxyGroupOverride> groupOverrides)?  $default,) {final _that = this;
switch (_that) {
case _Profile() when $default != null:
return $default(_that.id,_that.label,_that.currentGroupName,_that.url,_that.lastUpdateDate,_that.autoUpdateDuration,_that.subscriptionInfo,_that.autoUpdate,_that.selectedMap,_that.unfoldSet,_that.overrideData,_that.isUpdating,_that.useScriptOverride,_that.scriptId,_that.ageSecretKey,_that.groupSwitches,_that.groupOverrides);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Profile implements Profile {
  const _Profile({required this.id, this.label, this.currentGroupName, this.url = '', this.lastUpdateDate, required this.autoUpdateDuration, this.subscriptionInfo, this.autoUpdate = true,  SelectedMap selectedMap = const {},  Set<String> unfoldSet = const {}, this.overrideData = const OverrideData(), @JsonKey(includeToJson: false, includeFromJson: false) this.isUpdating = false, this.useScriptOverride = false, this.scriptId, this.ageSecretKey, @JsonKey(name: 'group-switches')  Map<String, bool> groupSwitches = const {}, @JsonKey(name: 'group-overrides')  Map<String, ProxyGroupOverride> groupOverrides = const {}}): _selectedMap = selectedMap,_unfoldSet = unfoldSet,_groupSwitches = groupSwitches,_groupOverrides = groupOverrides;
  factory _Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

@override final  String id;
@override final  String? label;
@override final  String? currentGroupName;
@override@JsonKey() final  String url;
@override final  DateTime? lastUpdateDate;
@override final  Duration autoUpdateDuration;
@override final  SubscriptionInfo? subscriptionInfo;
@override@JsonKey() final  bool autoUpdate;
 final  SelectedMap _selectedMap;
@override@JsonKey() SelectedMap get selectedMap {
  if (_selectedMap is EqualUnmodifiableMapView) return _selectedMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_selectedMap);
}

 final  Set<String> _unfoldSet;
@override@JsonKey() Set<String> get unfoldSet {
  if (_unfoldSet is EqualUnmodifiableSetView) return _unfoldSet;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_unfoldSet);
}

@override@JsonKey() final  OverrideData overrideData;
@override@JsonKey(includeToJson: false, includeFromJson: false) final  bool isUpdating;
@override@JsonKey() final  bool useScriptOverride;
@override final  String? scriptId;
@override final  String? ageSecretKey;
 final  Map<String, bool> _groupSwitches;
@override@JsonKey(name: 'group-switches') Map<String, bool> get groupSwitches {
  if (_groupSwitches is EqualUnmodifiableMapView) return _groupSwitches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_groupSwitches);
}

 final  Map<String, ProxyGroupOverride> _groupOverrides;
@override@JsonKey(name: 'group-overrides') Map<String, ProxyGroupOverride> get groupOverrides {
  if (_groupOverrides is EqualUnmodifiableMapView) return _groupOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_groupOverrides);
}


/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileCopyWith<_Profile> get copyWith => __$ProfileCopyWithImpl<_Profile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.currentGroupName, currentGroupName) || other.currentGroupName == currentGroupName)&&(identical(other.url, url) || other.url == url)&&(identical(other.lastUpdateDate, lastUpdateDate) || other.lastUpdateDate == lastUpdateDate)&&(identical(other.autoUpdateDuration, autoUpdateDuration) || other.autoUpdateDuration == autoUpdateDuration)&&(identical(other.subscriptionInfo, subscriptionInfo) || other.subscriptionInfo == subscriptionInfo)&&(identical(other.autoUpdate, autoUpdate) || other.autoUpdate == autoUpdate)&&const DeepCollectionEquality().equals(other.selectedMap, _selectedMap)&&const DeepCollectionEquality().equals(other.unfoldSet, _unfoldSet)&&(identical(other.overrideData, overrideData) || other.overrideData == overrideData)&&(identical(other.isUpdating, isUpdating) || other.isUpdating == isUpdating)&&(identical(other.useScriptOverride, useScriptOverride) || other.useScriptOverride == useScriptOverride)&&(identical(other.scriptId, scriptId) || other.scriptId == scriptId)&&(identical(other.ageSecretKey, ageSecretKey) || other.ageSecretKey == ageSecretKey)&&const DeepCollectionEquality().equals(other.groupSwitches, _groupSwitches)&&const DeepCollectionEquality().equals(other.groupOverrides, _groupOverrides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,label,currentGroupName,url,lastUpdateDate,autoUpdateDuration,subscriptionInfo,autoUpdate,const DeepCollectionEquality().hash(_selectedMap),const DeepCollectionEquality().hash(_unfoldSet),overrideData,isUpdating,useScriptOverride,scriptId,ageSecretKey,const DeepCollectionEquality().hash(_groupSwitches),const DeepCollectionEquality().hash(_groupOverrides));
}

@override
String toString() {
    return 'Profile(id: $id, label: $label, currentGroupName: $currentGroupName, url: $url, lastUpdateDate: $lastUpdateDate, autoUpdateDuration: $autoUpdateDuration, subscriptionInfo: $subscriptionInfo, autoUpdate: $autoUpdate, selectedMap: $selectedMap, unfoldSet: $unfoldSet, overrideData: $overrideData, isUpdating: $isUpdating, useScriptOverride: $useScriptOverride, scriptId: $scriptId, ageSecretKey: $ageSecretKey, groupSwitches: $groupSwitches, groupOverrides: $groupOverrides)';
}


}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) = __$ProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String? label, String? currentGroupName, String url, DateTime? lastUpdateDate, Duration autoUpdateDuration, SubscriptionInfo? subscriptionInfo, bool autoUpdate, SelectedMap selectedMap, Set<String> unfoldSet, OverrideData overrideData,@JsonKey(includeToJson: false, includeFromJson: false) bool isUpdating, bool useScriptOverride, String? scriptId, String? ageSecretKey,@JsonKey(name: 'group-switches') Map<String, bool> groupSwitches,@JsonKey(name: 'group-overrides') Map<String, ProxyGroupOverride> groupOverrides
});


@override $SubscriptionInfoCopyWith<$Res>? get subscriptionInfo;@override $OverrideDataCopyWith<$Res> get overrideData;

}
/// @nodoc
class __$ProfileCopyWithImpl<$Res>
    implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = freezed,Object? currentGroupName = freezed,Object? url = null,Object? lastUpdateDate = freezed,Object? autoUpdateDuration = null,Object? subscriptionInfo = freezed,Object? autoUpdate = null,Object? selectedMap = null,Object? unfoldSet = null,Object? overrideData = null,Object? isUpdating = null,Object? useScriptOverride = null,Object? scriptId = freezed,Object? ageSecretKey = freezed,Object? groupSwitches = null,Object? groupOverrides = null,}) {
  return _then(_Profile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,currentGroupName: freezed == currentGroupName ? _self.currentGroupName : currentGroupName // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,lastUpdateDate: freezed == lastUpdateDate ? _self.lastUpdateDate : lastUpdateDate // ignore: cast_nullable_to_non_nullable
as DateTime?,autoUpdateDuration: null == autoUpdateDuration ? _self.autoUpdateDuration : autoUpdateDuration // ignore: cast_nullable_to_non_nullable
as Duration,subscriptionInfo: freezed == subscriptionInfo ? _self.subscriptionInfo : subscriptionInfo // ignore: cast_nullable_to_non_nullable
as SubscriptionInfo?,autoUpdate: null == autoUpdate ? _self.autoUpdate : autoUpdate // ignore: cast_nullable_to_non_nullable
as bool,selectedMap: null == selectedMap ? _self._selectedMap : selectedMap // ignore: cast_nullable_to_non_nullable
as SelectedMap,unfoldSet: null == unfoldSet ? _self._unfoldSet : unfoldSet // ignore: cast_nullable_to_non_nullable
as Set<String>,overrideData: null == overrideData ? _self.overrideData : overrideData // ignore: cast_nullable_to_non_nullable
as OverrideData,isUpdating: null == isUpdating ? _self.isUpdating : isUpdating // ignore: cast_nullable_to_non_nullable
as bool,useScriptOverride: null == useScriptOverride ? _self.useScriptOverride : useScriptOverride // ignore: cast_nullable_to_non_nullable
as bool,scriptId: freezed == scriptId ? _self.scriptId : scriptId // ignore: cast_nullable_to_non_nullable
as String?,ageSecretKey: freezed == ageSecretKey ? _self.ageSecretKey : ageSecretKey // ignore: cast_nullable_to_non_nullable
as String?,groupSwitches: null == groupSwitches ? _self._groupSwitches : groupSwitches // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,groupOverrides: null == groupOverrides ? _self._groupOverrides : groupOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, ProxyGroupOverride>,
  ));
}

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionInfoCopyWith<$Res>? get subscriptionInfo {
    if (_self.subscriptionInfo == null) {
    return null;
  }

  return $SubscriptionInfoCopyWith<$Res>(_self.subscriptionInfo!, (value) {
    return _then(_self.copyWith(subscriptionInfo: value));
  });
}/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OverrideDataCopyWith<$Res> get overrideData {
  
  return $OverrideDataCopyWith<$Res>(_self.overrideData, (value) {
    return _then(_self.copyWith(overrideData: value));
  });
}
}


/// @nodoc
mixin _$OverrideData {

 bool get enable; OverrideRule get rule;
/// Create a copy of OverrideData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverrideDataCopyWith<OverrideData> get copyWith => _$OverrideDataCopyWithImpl<OverrideData>(this as OverrideData, _$identity);

  /// Serializes this OverrideData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OverrideData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverrideData&&(identical(other.enable, _this.enable) || other.enable == _this.enable)&&(identical(other.rule, _this.rule) || other.rule == _this.rule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OverrideData;
  return Object.hash(runtimeType,_this.enable,_this.rule);
}

@override
String toString() {
  final _this = this as OverrideData;
  return 'OverrideData(enable: ${_this.enable}, rule: ${_this.rule})';
}


}

/// @nodoc
abstract mixin class $OverrideDataCopyWith<$Res>  {
  factory $OverrideDataCopyWith(OverrideData value, $Res Function(OverrideData) _then) = _$OverrideDataCopyWithImpl;
@useResult
$Res call({
 bool enable, OverrideRule rule
});


$OverrideRuleCopyWith<$Res> get rule;

}
/// @nodoc
class _$OverrideDataCopyWithImpl<$Res>
    implements $OverrideDataCopyWith<$Res> {
  _$OverrideDataCopyWithImpl(this._self, this._then);

  final OverrideData _self;
  final $Res Function(OverrideData) _then;

/// Create a copy of OverrideData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enable = null,Object? rule = null,}) {
  return _then(OverrideData(
enable: null == enable ? _self.enable : enable // ignore: cast_nullable_to_non_nullable
as bool,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as OverrideRule,
  ));
}
/// Create a copy of OverrideData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OverrideRuleCopyWith<$Res> get rule {
  
  return $OverrideRuleCopyWith<$Res>(_self.rule, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}


/// Adds pattern-matching-related methods to [OverrideData].
extension OverrideDataPatterns on OverrideData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverrideData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverrideData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverrideData value)  $default,){
final _that = this;
switch (_that) {
case _OverrideData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverrideData value)?  $default,){
final _that = this;
switch (_that) {
case _OverrideData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enable,  OverrideRule rule)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverrideData() when $default != null:
return $default(_that.enable,_that.rule);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enable,  OverrideRule rule)  $default,) {final _that = this;
switch (_that) {
case _OverrideData():
return $default(_that.enable,_that.rule);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enable,  OverrideRule rule)?  $default,) {final _that = this;
switch (_that) {
case _OverrideData() when $default != null:
return $default(_that.enable,_that.rule);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OverrideData implements OverrideData {
  const _OverrideData({this.enable = false, this.rule = const OverrideRule()});
  factory _OverrideData.fromJson(Map<String, dynamic> json) => _$OverrideDataFromJson(json);

@override@JsonKey() final  bool enable;
@override@JsonKey() final  OverrideRule rule;

/// Create a copy of OverrideData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverrideDataCopyWith<_OverrideData> get copyWith => __$OverrideDataCopyWithImpl<_OverrideData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OverrideDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverrideData&&(identical(other.enable, enable) || other.enable == enable)&&(identical(other.rule, rule) || other.rule == rule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enable,rule);
}

@override
String toString() {
    return 'OverrideData(enable: $enable, rule: $rule)';
}


}

/// @nodoc
abstract mixin class _$OverrideDataCopyWith<$Res> implements $OverrideDataCopyWith<$Res> {
  factory _$OverrideDataCopyWith(_OverrideData value, $Res Function(_OverrideData) _then) = __$OverrideDataCopyWithImpl;
@override @useResult
$Res call({
 bool enable, OverrideRule rule
});


@override $OverrideRuleCopyWith<$Res> get rule;

}
/// @nodoc
class __$OverrideDataCopyWithImpl<$Res>
    implements _$OverrideDataCopyWith<$Res> {
  __$OverrideDataCopyWithImpl(this._self, this._then);

  final _OverrideData _self;
  final $Res Function(_OverrideData) _then;

/// Create a copy of OverrideData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enable = null,Object? rule = null,}) {
  return _then(_OverrideData(
enable: null == enable ? _self.enable : enable // ignore: cast_nullable_to_non_nullable
as bool,rule: null == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as OverrideRule,
  ));
}

/// Create a copy of OverrideData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OverrideRuleCopyWith<$Res> get rule {
  
  return $OverrideRuleCopyWith<$Res>(_self.rule, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}


/// @nodoc
mixin _$OverrideRule {

 OverrideRuleType get type; List<Rule> get overrideRules; List<Rule> get addedRules;
/// Create a copy of OverrideRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverrideRuleCopyWith<OverrideRule> get copyWith => _$OverrideRuleCopyWithImpl<OverrideRule>(this as OverrideRule, _$identity);

  /// Serializes this OverrideRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as OverrideRule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverrideRule&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.overrideRules, _this.overrideRules)&&const DeepCollectionEquality().equals(other.addedRules, _this.addedRules));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OverrideRule;
  return Object.hash(runtimeType,_this.type,const DeepCollectionEquality().hash(_this.overrideRules),const DeepCollectionEquality().hash(_this.addedRules));
}

@override
String toString() {
  final _this = this as OverrideRule;
  return 'OverrideRule(type: ${_this.type}, overrideRules: ${_this.overrideRules}, addedRules: ${_this.addedRules})';
}


}

/// @nodoc
abstract mixin class $OverrideRuleCopyWith<$Res>  {
  factory $OverrideRuleCopyWith(OverrideRule value, $Res Function(OverrideRule) _then) = _$OverrideRuleCopyWithImpl;
@useResult
$Res call({
 OverrideRuleType type, List<Rule> overrideRules, List<Rule> addedRules
});




}
/// @nodoc
class _$OverrideRuleCopyWithImpl<$Res>
    implements $OverrideRuleCopyWith<$Res> {
  _$OverrideRuleCopyWithImpl(this._self, this._then);

  final OverrideRule _self;
  final $Res Function(OverrideRule) _then;

/// Create a copy of OverrideRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? overrideRules = null,Object? addedRules = null,}) {
  return _then(OverrideRule(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OverrideRuleType,overrideRules: null == overrideRules ? _self.overrideRules : overrideRules // ignore: cast_nullable_to_non_nullable
as List<Rule>,addedRules: null == addedRules ? _self.addedRules : addedRules // ignore: cast_nullable_to_non_nullable
as List<Rule>,
  ));
}

}


/// Adds pattern-matching-related methods to [OverrideRule].
extension OverrideRulePatterns on OverrideRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverrideRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverrideRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverrideRule value)  $default,){
final _that = this;
switch (_that) {
case _OverrideRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverrideRule value)?  $default,){
final _that = this;
switch (_that) {
case _OverrideRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OverrideRuleType type,  List<Rule> overrideRules,  List<Rule> addedRules)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverrideRule() when $default != null:
return $default(_that.type,_that.overrideRules,_that.addedRules);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OverrideRuleType type,  List<Rule> overrideRules,  List<Rule> addedRules)  $default,) {final _that = this;
switch (_that) {
case _OverrideRule():
return $default(_that.type,_that.overrideRules,_that.addedRules);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OverrideRuleType type,  List<Rule> overrideRules,  List<Rule> addedRules)?  $default,) {final _that = this;
switch (_that) {
case _OverrideRule() when $default != null:
return $default(_that.type,_that.overrideRules,_that.addedRules);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OverrideRule implements OverrideRule {
  const _OverrideRule({this.type = OverrideRuleType.added,  List<Rule> overrideRules = const [],  List<Rule> addedRules = const []}): _overrideRules = overrideRules,_addedRules = addedRules;
  factory _OverrideRule.fromJson(Map<String, dynamic> json) => _$OverrideRuleFromJson(json);

@override@JsonKey() final  OverrideRuleType type;
 final  List<Rule> _overrideRules;
@override@JsonKey() List<Rule> get overrideRules {
  if (_overrideRules is EqualUnmodifiableListView) return _overrideRules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_overrideRules);
}

 final  List<Rule> _addedRules;
@override@JsonKey() List<Rule> get addedRules {
  if (_addedRules is EqualUnmodifiableListView) return _addedRules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addedRules);
}


/// Create a copy of OverrideRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverrideRuleCopyWith<_OverrideRule> get copyWith => __$OverrideRuleCopyWithImpl<_OverrideRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OverrideRuleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverrideRule&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.overrideRules, _overrideRules)&&const DeepCollectionEquality().equals(other.addedRules, _addedRules));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_overrideRules),const DeepCollectionEquality().hash(_addedRules));
}

@override
String toString() {
    return 'OverrideRule(type: $type, overrideRules: $overrideRules, addedRules: $addedRules)';
}


}

/// @nodoc
abstract mixin class _$OverrideRuleCopyWith<$Res> implements $OverrideRuleCopyWith<$Res> {
  factory _$OverrideRuleCopyWith(_OverrideRule value, $Res Function(_OverrideRule) _then) = __$OverrideRuleCopyWithImpl;
@override @useResult
$Res call({
 OverrideRuleType type, List<Rule> overrideRules, List<Rule> addedRules
});




}
/// @nodoc
class __$OverrideRuleCopyWithImpl<$Res>
    implements _$OverrideRuleCopyWith<$Res> {
  __$OverrideRuleCopyWithImpl(this._self, this._then);

  final _OverrideRule _self;
  final $Res Function(_OverrideRule) _then;

/// Create a copy of OverrideRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? overrideRules = null,Object? addedRules = null,}) {
  return _then(_OverrideRule(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OverrideRuleType,overrideRules: null == overrideRules ? _self._overrideRules : overrideRules // ignore: cast_nullable_to_non_nullable
as List<Rule>,addedRules: null == addedRules ? _self._addedRules : addedRules // ignore: cast_nullable_to_non_nullable
as List<Rule>,
  ));
}


}


/// @nodoc
mixin _$ProxyGroupOverride {

 String? get url; int? get interval; bool? get lazy; int? get timeout;@JsonKey(name: 'max-failed-times') int? get maxFailedTimes; String? get filter;@JsonKey(name: 'exclude-filter') String? get excludeFilter;@JsonKey(name: 'exclude-type') String? get excludeType;@JsonKey(name: 'expected-status') String? get expectedStatus; bool? get hidden; String? get icon; int? get tolerance;@JsonKey(name: 'default-selected') String? get defaultSelected;@JsonKey(name: 'empty-fallback') String? get emptyFallback;@JsonKey(name: 'disable-udp') bool? get disableUdp;@JsonKey(name: 'include-all') bool? get includeAll;@JsonKey(name: 'include-all-proxies') bool? get includeAllProxies;@JsonKey(name: 'include-all-providers') bool? get includeAllProviders; String? get strategy;
/// Create a copy of ProxyGroupOverride
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProxyGroupOverrideCopyWith<ProxyGroupOverride> get copyWith => _$ProxyGroupOverrideCopyWithImpl<ProxyGroupOverride>(this as ProxyGroupOverride, _$identity);

  /// Serializes this ProxyGroupOverride to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProxyGroupOverride;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProxyGroupOverride&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.interval, _this.interval) || other.interval == _this.interval)&&(identical(other.lazy, _this.lazy) || other.lazy == _this.lazy)&&(identical(other.timeout, _this.timeout) || other.timeout == _this.timeout)&&(identical(other.maxFailedTimes, _this.maxFailedTimes) || other.maxFailedTimes == _this.maxFailedTimes)&&(identical(other.filter, _this.filter) || other.filter == _this.filter)&&(identical(other.excludeFilter, _this.excludeFilter) || other.excludeFilter == _this.excludeFilter)&&(identical(other.excludeType, _this.excludeType) || other.excludeType == _this.excludeType)&&(identical(other.expectedStatus, _this.expectedStatus) || other.expectedStatus == _this.expectedStatus)&&(identical(other.hidden, _this.hidden) || other.hidden == _this.hidden)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.tolerance, _this.tolerance) || other.tolerance == _this.tolerance)&&(identical(other.defaultSelected, _this.defaultSelected) || other.defaultSelected == _this.defaultSelected)&&(identical(other.emptyFallback, _this.emptyFallback) || other.emptyFallback == _this.emptyFallback)&&(identical(other.disableUdp, _this.disableUdp) || other.disableUdp == _this.disableUdp)&&(identical(other.includeAll, _this.includeAll) || other.includeAll == _this.includeAll)&&(identical(other.includeAllProxies, _this.includeAllProxies) || other.includeAllProxies == _this.includeAllProxies)&&(identical(other.includeAllProviders, _this.includeAllProviders) || other.includeAllProviders == _this.includeAllProviders)&&(identical(other.strategy, _this.strategy) || other.strategy == _this.strategy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProxyGroupOverride;
  return Object.hashAll([runtimeType,_this.url,_this.interval,_this.lazy,_this.timeout,_this.maxFailedTimes,_this.filter,_this.excludeFilter,_this.excludeType,_this.expectedStatus,_this.hidden,_this.icon,_this.tolerance,_this.defaultSelected,_this.emptyFallback,_this.disableUdp,_this.includeAll,_this.includeAllProxies,_this.includeAllProviders,_this.strategy]);
}

@override
String toString() {
  final _this = this as ProxyGroupOverride;
  return 'ProxyGroupOverride(url: ${_this.url}, interval: ${_this.interval}, lazy: ${_this.lazy}, timeout: ${_this.timeout}, maxFailedTimes: ${_this.maxFailedTimes}, filter: ${_this.filter}, excludeFilter: ${_this.excludeFilter}, excludeType: ${_this.excludeType}, expectedStatus: ${_this.expectedStatus}, hidden: ${_this.hidden}, icon: ${_this.icon}, tolerance: ${_this.tolerance}, defaultSelected: ${_this.defaultSelected}, emptyFallback: ${_this.emptyFallback}, disableUdp: ${_this.disableUdp}, includeAll: ${_this.includeAll}, includeAllProxies: ${_this.includeAllProxies}, includeAllProviders: ${_this.includeAllProviders}, strategy: ${_this.strategy})';
}


}

/// @nodoc
abstract mixin class $ProxyGroupOverrideCopyWith<$Res>  {
  factory $ProxyGroupOverrideCopyWith(ProxyGroupOverride value, $Res Function(ProxyGroupOverride) _then) = _$ProxyGroupOverrideCopyWithImpl;
@useResult
$Res call({
 String? url, int? interval, bool? lazy, int? timeout,@JsonKey(name: 'max-failed-times') int? maxFailedTimes, String? filter,@JsonKey(name: 'exclude-filter') String? excludeFilter,@JsonKey(name: 'exclude-type') String? excludeType,@JsonKey(name: 'expected-status') String? expectedStatus, bool? hidden, String? icon, int? tolerance,@JsonKey(name: 'default-selected') String? defaultSelected,@JsonKey(name: 'empty-fallback') String? emptyFallback,@JsonKey(name: 'disable-udp') bool? disableUdp,@JsonKey(name: 'include-all') bool? includeAll,@JsonKey(name: 'include-all-proxies') bool? includeAllProxies,@JsonKey(name: 'include-all-providers') bool? includeAllProviders, String? strategy
});




}
/// @nodoc
class _$ProxyGroupOverrideCopyWithImpl<$Res>
    implements $ProxyGroupOverrideCopyWith<$Res> {
  _$ProxyGroupOverrideCopyWithImpl(this._self, this._then);

  final ProxyGroupOverride _self;
  final $Res Function(ProxyGroupOverride) _then;

/// Create a copy of ProxyGroupOverride
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = freezed,Object? interval = freezed,Object? lazy = freezed,Object? timeout = freezed,Object? maxFailedTimes = freezed,Object? filter = freezed,Object? excludeFilter = freezed,Object? excludeType = freezed,Object? expectedStatus = freezed,Object? hidden = freezed,Object? icon = freezed,Object? tolerance = freezed,Object? defaultSelected = freezed,Object? emptyFallback = freezed,Object? disableUdp = freezed,Object? includeAll = freezed,Object? includeAllProxies = freezed,Object? includeAllProviders = freezed,Object? strategy = freezed,}) {
  return _then(ProxyGroupOverride(
url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,interval: freezed == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int?,lazy: freezed == lazy ? _self.lazy : lazy // ignore: cast_nullable_to_non_nullable
as bool?,timeout: freezed == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as int?,maxFailedTimes: freezed == maxFailedTimes ? _self.maxFailedTimes : maxFailedTimes // ignore: cast_nullable_to_non_nullable
as int?,filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String?,excludeFilter: freezed == excludeFilter ? _self.excludeFilter : excludeFilter // ignore: cast_nullable_to_non_nullable
as String?,excludeType: freezed == excludeType ? _self.excludeType : excludeType // ignore: cast_nullable_to_non_nullable
as String?,expectedStatus: freezed == expectedStatus ? _self.expectedStatus : expectedStatus // ignore: cast_nullable_to_non_nullable
as String?,hidden: freezed == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,tolerance: freezed == tolerance ? _self.tolerance : tolerance // ignore: cast_nullable_to_non_nullable
as int?,defaultSelected: freezed == defaultSelected ? _self.defaultSelected : defaultSelected // ignore: cast_nullable_to_non_nullable
as String?,emptyFallback: freezed == emptyFallback ? _self.emptyFallback : emptyFallback // ignore: cast_nullable_to_non_nullable
as String?,disableUdp: freezed == disableUdp ? _self.disableUdp : disableUdp // ignore: cast_nullable_to_non_nullable
as bool?,includeAll: freezed == includeAll ? _self.includeAll : includeAll // ignore: cast_nullable_to_non_nullable
as bool?,includeAllProxies: freezed == includeAllProxies ? _self.includeAllProxies : includeAllProxies // ignore: cast_nullable_to_non_nullable
as bool?,includeAllProviders: freezed == includeAllProviders ? _self.includeAllProviders : includeAllProviders // ignore: cast_nullable_to_non_nullable
as bool?,strategy: freezed == strategy ? _self.strategy : strategy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProxyGroupOverride].
extension ProxyGroupOverridePatterns on ProxyGroupOverride {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProxyGroupOverride value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProxyGroupOverride() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProxyGroupOverride value)  $default,){
final _that = this;
switch (_that) {
case _ProxyGroupOverride():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProxyGroupOverride value)?  $default,){
final _that = this;
switch (_that) {
case _ProxyGroupOverride() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? url,  int? interval,  bool? lazy,  int? timeout, @JsonKey(name: 'max-failed-times')  int? maxFailedTimes,  String? filter, @JsonKey(name: 'exclude-filter')  String? excludeFilter, @JsonKey(name: 'exclude-type')  String? excludeType, @JsonKey(name: 'expected-status')  String? expectedStatus,  bool? hidden,  String? icon,  int? tolerance, @JsonKey(name: 'default-selected')  String? defaultSelected, @JsonKey(name: 'empty-fallback')  String? emptyFallback, @JsonKey(name: 'disable-udp')  bool? disableUdp, @JsonKey(name: 'include-all')  bool? includeAll, @JsonKey(name: 'include-all-proxies')  bool? includeAllProxies, @JsonKey(name: 'include-all-providers')  bool? includeAllProviders,  String? strategy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProxyGroupOverride() when $default != null:
return $default(_that.url,_that.interval,_that.lazy,_that.timeout,_that.maxFailedTimes,_that.filter,_that.excludeFilter,_that.excludeType,_that.expectedStatus,_that.hidden,_that.icon,_that.tolerance,_that.defaultSelected,_that.emptyFallback,_that.disableUdp,_that.includeAll,_that.includeAllProxies,_that.includeAllProviders,_that.strategy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? url,  int? interval,  bool? lazy,  int? timeout, @JsonKey(name: 'max-failed-times')  int? maxFailedTimes,  String? filter, @JsonKey(name: 'exclude-filter')  String? excludeFilter, @JsonKey(name: 'exclude-type')  String? excludeType, @JsonKey(name: 'expected-status')  String? expectedStatus,  bool? hidden,  String? icon,  int? tolerance, @JsonKey(name: 'default-selected')  String? defaultSelected, @JsonKey(name: 'empty-fallback')  String? emptyFallback, @JsonKey(name: 'disable-udp')  bool? disableUdp, @JsonKey(name: 'include-all')  bool? includeAll, @JsonKey(name: 'include-all-proxies')  bool? includeAllProxies, @JsonKey(name: 'include-all-providers')  bool? includeAllProviders,  String? strategy)  $default,) {final _that = this;
switch (_that) {
case _ProxyGroupOverride():
return $default(_that.url,_that.interval,_that.lazy,_that.timeout,_that.maxFailedTimes,_that.filter,_that.excludeFilter,_that.excludeType,_that.expectedStatus,_that.hidden,_that.icon,_that.tolerance,_that.defaultSelected,_that.emptyFallback,_that.disableUdp,_that.includeAll,_that.includeAllProxies,_that.includeAllProviders,_that.strategy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? url,  int? interval,  bool? lazy,  int? timeout, @JsonKey(name: 'max-failed-times')  int? maxFailedTimes,  String? filter, @JsonKey(name: 'exclude-filter')  String? excludeFilter, @JsonKey(name: 'exclude-type')  String? excludeType, @JsonKey(name: 'expected-status')  String? expectedStatus,  bool? hidden,  String? icon,  int? tolerance, @JsonKey(name: 'default-selected')  String? defaultSelected, @JsonKey(name: 'empty-fallback')  String? emptyFallback, @JsonKey(name: 'disable-udp')  bool? disableUdp, @JsonKey(name: 'include-all')  bool? includeAll, @JsonKey(name: 'include-all-proxies')  bool? includeAllProxies, @JsonKey(name: 'include-all-providers')  bool? includeAllProviders,  String? strategy)?  $default,) {final _that = this;
switch (_that) {
case _ProxyGroupOverride() when $default != null:
return $default(_that.url,_that.interval,_that.lazy,_that.timeout,_that.maxFailedTimes,_that.filter,_that.excludeFilter,_that.excludeType,_that.expectedStatus,_that.hidden,_that.icon,_that.tolerance,_that.defaultSelected,_that.emptyFallback,_that.disableUdp,_that.includeAll,_that.includeAllProxies,_that.includeAllProviders,_that.strategy);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false)
class _ProxyGroupOverride implements ProxyGroupOverride {
  const _ProxyGroupOverride({this.url, this.interval, this.lazy, this.timeout, @JsonKey(name: 'max-failed-times') this.maxFailedTimes, this.filter, @JsonKey(name: 'exclude-filter') this.excludeFilter, @JsonKey(name: 'exclude-type') this.excludeType, @JsonKey(name: 'expected-status') this.expectedStatus, this.hidden, this.icon, this.tolerance, @JsonKey(name: 'default-selected') this.defaultSelected, @JsonKey(name: 'empty-fallback') this.emptyFallback, @JsonKey(name: 'disable-udp') this.disableUdp, @JsonKey(name: 'include-all') this.includeAll, @JsonKey(name: 'include-all-proxies') this.includeAllProxies, @JsonKey(name: 'include-all-providers') this.includeAllProviders, this.strategy});
  factory _ProxyGroupOverride.fromJson(Map<String, dynamic> json) => _$ProxyGroupOverrideFromJson(json);

@override final  String? url;
@override final  int? interval;
@override final  bool? lazy;
@override final  int? timeout;
@override@JsonKey(name: 'max-failed-times') final  int? maxFailedTimes;
@override final  String? filter;
@override@JsonKey(name: 'exclude-filter') final  String? excludeFilter;
@override@JsonKey(name: 'exclude-type') final  String? excludeType;
@override@JsonKey(name: 'expected-status') final  String? expectedStatus;
@override final  bool? hidden;
@override final  String? icon;
@override final  int? tolerance;
@override@JsonKey(name: 'default-selected') final  String? defaultSelected;
@override@JsonKey(name: 'empty-fallback') final  String? emptyFallback;
@override@JsonKey(name: 'disable-udp') final  bool? disableUdp;
@override@JsonKey(name: 'include-all') final  bool? includeAll;
@override@JsonKey(name: 'include-all-proxies') final  bool? includeAllProxies;
@override@JsonKey(name: 'include-all-providers') final  bool? includeAllProviders;
@override final  String? strategy;

/// Create a copy of ProxyGroupOverride
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProxyGroupOverrideCopyWith<_ProxyGroupOverride> get copyWith => __$ProxyGroupOverrideCopyWithImpl<_ProxyGroupOverride>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProxyGroupOverrideToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProxyGroupOverride&&(identical(other.url, url) || other.url == url)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.lazy, lazy) || other.lazy == lazy)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.maxFailedTimes, maxFailedTimes) || other.maxFailedTimes == maxFailedTimes)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.excludeFilter, excludeFilter) || other.excludeFilter == excludeFilter)&&(identical(other.excludeType, excludeType) || other.excludeType == excludeType)&&(identical(other.expectedStatus, expectedStatus) || other.expectedStatus == expectedStatus)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.tolerance, tolerance) || other.tolerance == tolerance)&&(identical(other.defaultSelected, defaultSelected) || other.defaultSelected == defaultSelected)&&(identical(other.emptyFallback, emptyFallback) || other.emptyFallback == emptyFallback)&&(identical(other.disableUdp, disableUdp) || other.disableUdp == disableUdp)&&(identical(other.includeAll, includeAll) || other.includeAll == includeAll)&&(identical(other.includeAllProxies, includeAllProxies) || other.includeAllProxies == includeAllProxies)&&(identical(other.includeAllProviders, includeAllProviders) || other.includeAllProviders == includeAllProviders)&&(identical(other.strategy, strategy) || other.strategy == strategy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,url,interval,lazy,timeout,maxFailedTimes,filter,excludeFilter,excludeType,expectedStatus,hidden,icon,tolerance,defaultSelected,emptyFallback,disableUdp,includeAll,includeAllProxies,includeAllProviders,strategy]);
}

@override
String toString() {
    return 'ProxyGroupOverride(url: $url, interval: $interval, lazy: $lazy, timeout: $timeout, maxFailedTimes: $maxFailedTimes, filter: $filter, excludeFilter: $excludeFilter, excludeType: $excludeType, expectedStatus: $expectedStatus, hidden: $hidden, icon: $icon, tolerance: $tolerance, defaultSelected: $defaultSelected, emptyFallback: $emptyFallback, disableUdp: $disableUdp, includeAll: $includeAll, includeAllProxies: $includeAllProxies, includeAllProviders: $includeAllProviders, strategy: $strategy)';
}


}

/// @nodoc
abstract mixin class _$ProxyGroupOverrideCopyWith<$Res> implements $ProxyGroupOverrideCopyWith<$Res> {
  factory _$ProxyGroupOverrideCopyWith(_ProxyGroupOverride value, $Res Function(_ProxyGroupOverride) _then) = __$ProxyGroupOverrideCopyWithImpl;
@override @useResult
$Res call({
 String? url, int? interval, bool? lazy, int? timeout,@JsonKey(name: 'max-failed-times') int? maxFailedTimes, String? filter,@JsonKey(name: 'exclude-filter') String? excludeFilter,@JsonKey(name: 'exclude-type') String? excludeType,@JsonKey(name: 'expected-status') String? expectedStatus, bool? hidden, String? icon, int? tolerance,@JsonKey(name: 'default-selected') String? defaultSelected,@JsonKey(name: 'empty-fallback') String? emptyFallback,@JsonKey(name: 'disable-udp') bool? disableUdp,@JsonKey(name: 'include-all') bool? includeAll,@JsonKey(name: 'include-all-proxies') bool? includeAllProxies,@JsonKey(name: 'include-all-providers') bool? includeAllProviders, String? strategy
});




}
/// @nodoc
class __$ProxyGroupOverrideCopyWithImpl<$Res>
    implements _$ProxyGroupOverrideCopyWith<$Res> {
  __$ProxyGroupOverrideCopyWithImpl(this._self, this._then);

  final _ProxyGroupOverride _self;
  final $Res Function(_ProxyGroupOverride) _then;

/// Create a copy of ProxyGroupOverride
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = freezed,Object? interval = freezed,Object? lazy = freezed,Object? timeout = freezed,Object? maxFailedTimes = freezed,Object? filter = freezed,Object? excludeFilter = freezed,Object? excludeType = freezed,Object? expectedStatus = freezed,Object? hidden = freezed,Object? icon = freezed,Object? tolerance = freezed,Object? defaultSelected = freezed,Object? emptyFallback = freezed,Object? disableUdp = freezed,Object? includeAll = freezed,Object? includeAllProxies = freezed,Object? includeAllProviders = freezed,Object? strategy = freezed,}) {
  return _then(_ProxyGroupOverride(
url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,interval: freezed == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int?,lazy: freezed == lazy ? _self.lazy : lazy // ignore: cast_nullable_to_non_nullable
as bool?,timeout: freezed == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as int?,maxFailedTimes: freezed == maxFailedTimes ? _self.maxFailedTimes : maxFailedTimes // ignore: cast_nullable_to_non_nullable
as int?,filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String?,excludeFilter: freezed == excludeFilter ? _self.excludeFilter : excludeFilter // ignore: cast_nullable_to_non_nullable
as String?,excludeType: freezed == excludeType ? _self.excludeType : excludeType // ignore: cast_nullable_to_non_nullable
as String?,expectedStatus: freezed == expectedStatus ? _self.expectedStatus : expectedStatus // ignore: cast_nullable_to_non_nullable
as String?,hidden: freezed == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,tolerance: freezed == tolerance ? _self.tolerance : tolerance // ignore: cast_nullable_to_non_nullable
as int?,defaultSelected: freezed == defaultSelected ? _self.defaultSelected : defaultSelected // ignore: cast_nullable_to_non_nullable
as String?,emptyFallback: freezed == emptyFallback ? _self.emptyFallback : emptyFallback // ignore: cast_nullable_to_non_nullable
as String?,disableUdp: freezed == disableUdp ? _self.disableUdp : disableUdp // ignore: cast_nullable_to_non_nullable
as bool?,includeAll: freezed == includeAll ? _self.includeAll : includeAll // ignore: cast_nullable_to_non_nullable
as bool?,includeAllProxies: freezed == includeAllProxies ? _self.includeAllProxies : includeAllProxies // ignore: cast_nullable_to_non_nullable
as bool?,includeAllProviders: freezed == includeAllProviders ? _self.includeAllProviders : includeAllProviders // ignore: cast_nullable_to_non_nullable
as bool?,strategy: freezed == strategy ? _self.strategy : strategy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ProxyGroupParams {

 String get url; int? get interval; bool get lazy; int? get timeout; int? get maxFailedTimes; String get filter; String get excludeFilter; String get excludeType; String get expectedStatus; bool get hidden; String get icon; int? get tolerance; String get defaultSelected; String get emptyFallback; bool get disableUdp; bool get includeAll; bool get includeAllProxies; bool get includeAllProviders; String get strategy;
/// Create a copy of ProxyGroupParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProxyGroupParamsCopyWith<ProxyGroupParams> get copyWith => _$ProxyGroupParamsCopyWithImpl<ProxyGroupParams>(this as ProxyGroupParams, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ProxyGroupParams;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProxyGroupParams&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.interval, _this.interval) || other.interval == _this.interval)&&(identical(other.lazy, _this.lazy) || other.lazy == _this.lazy)&&(identical(other.timeout, _this.timeout) || other.timeout == _this.timeout)&&(identical(other.maxFailedTimes, _this.maxFailedTimes) || other.maxFailedTimes == _this.maxFailedTimes)&&(identical(other.filter, _this.filter) || other.filter == _this.filter)&&(identical(other.excludeFilter, _this.excludeFilter) || other.excludeFilter == _this.excludeFilter)&&(identical(other.excludeType, _this.excludeType) || other.excludeType == _this.excludeType)&&(identical(other.expectedStatus, _this.expectedStatus) || other.expectedStatus == _this.expectedStatus)&&(identical(other.hidden, _this.hidden) || other.hidden == _this.hidden)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.tolerance, _this.tolerance) || other.tolerance == _this.tolerance)&&(identical(other.defaultSelected, _this.defaultSelected) || other.defaultSelected == _this.defaultSelected)&&(identical(other.emptyFallback, _this.emptyFallback) || other.emptyFallback == _this.emptyFallback)&&(identical(other.disableUdp, _this.disableUdp) || other.disableUdp == _this.disableUdp)&&(identical(other.includeAll, _this.includeAll) || other.includeAll == _this.includeAll)&&(identical(other.includeAllProxies, _this.includeAllProxies) || other.includeAllProxies == _this.includeAllProxies)&&(identical(other.includeAllProviders, _this.includeAllProviders) || other.includeAllProviders == _this.includeAllProviders)&&(identical(other.strategy, _this.strategy) || other.strategy == _this.strategy));
}


@override
int get hashCode {
  final _this = this as ProxyGroupParams;
  return Object.hashAll([runtimeType,_this.url,_this.interval,_this.lazy,_this.timeout,_this.maxFailedTimes,_this.filter,_this.excludeFilter,_this.excludeType,_this.expectedStatus,_this.hidden,_this.icon,_this.tolerance,_this.defaultSelected,_this.emptyFallback,_this.disableUdp,_this.includeAll,_this.includeAllProxies,_this.includeAllProviders,_this.strategy]);
}

@override
String toString() {
  final _this = this as ProxyGroupParams;
  return 'ProxyGroupParams(url: ${_this.url}, interval: ${_this.interval}, lazy: ${_this.lazy}, timeout: ${_this.timeout}, maxFailedTimes: ${_this.maxFailedTimes}, filter: ${_this.filter}, excludeFilter: ${_this.excludeFilter}, excludeType: ${_this.excludeType}, expectedStatus: ${_this.expectedStatus}, hidden: ${_this.hidden}, icon: ${_this.icon}, tolerance: ${_this.tolerance}, defaultSelected: ${_this.defaultSelected}, emptyFallback: ${_this.emptyFallback}, disableUdp: ${_this.disableUdp}, includeAll: ${_this.includeAll}, includeAllProxies: ${_this.includeAllProxies}, includeAllProviders: ${_this.includeAllProviders}, strategy: ${_this.strategy})';
}


}

/// @nodoc
abstract mixin class $ProxyGroupParamsCopyWith<$Res>  {
  factory $ProxyGroupParamsCopyWith(ProxyGroupParams value, $Res Function(ProxyGroupParams) _then) = _$ProxyGroupParamsCopyWithImpl;
@useResult
$Res call({
 String url, int? interval, bool lazy, int? timeout, int? maxFailedTimes, String filter, String excludeFilter, String excludeType, String expectedStatus, bool hidden, String icon, int? tolerance, String defaultSelected, String emptyFallback, bool disableUdp, bool includeAll, bool includeAllProxies, bool includeAllProviders, String strategy
});




}
/// @nodoc
class _$ProxyGroupParamsCopyWithImpl<$Res>
    implements $ProxyGroupParamsCopyWith<$Res> {
  _$ProxyGroupParamsCopyWithImpl(this._self, this._then);

  final ProxyGroupParams _self;
  final $Res Function(ProxyGroupParams) _then;

/// Create a copy of ProxyGroupParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? interval = freezed,Object? lazy = null,Object? timeout = freezed,Object? maxFailedTimes = freezed,Object? filter = null,Object? excludeFilter = null,Object? excludeType = null,Object? expectedStatus = null,Object? hidden = null,Object? icon = null,Object? tolerance = freezed,Object? defaultSelected = null,Object? emptyFallback = null,Object? disableUdp = null,Object? includeAll = null,Object? includeAllProxies = null,Object? includeAllProviders = null,Object? strategy = null,}) {
  return _then(ProxyGroupParams(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,interval: freezed == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int?,lazy: null == lazy ? _self.lazy : lazy // ignore: cast_nullable_to_non_nullable
as bool,timeout: freezed == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as int?,maxFailedTimes: freezed == maxFailedTimes ? _self.maxFailedTimes : maxFailedTimes // ignore: cast_nullable_to_non_nullable
as int?,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String,excludeFilter: null == excludeFilter ? _self.excludeFilter : excludeFilter // ignore: cast_nullable_to_non_nullable
as String,excludeType: null == excludeType ? _self.excludeType : excludeType // ignore: cast_nullable_to_non_nullable
as String,expectedStatus: null == expectedStatus ? _self.expectedStatus : expectedStatus // ignore: cast_nullable_to_non_nullable
as String,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,tolerance: freezed == tolerance ? _self.tolerance : tolerance // ignore: cast_nullable_to_non_nullable
as int?,defaultSelected: null == defaultSelected ? _self.defaultSelected : defaultSelected // ignore: cast_nullable_to_non_nullable
as String,emptyFallback: null == emptyFallback ? _self.emptyFallback : emptyFallback // ignore: cast_nullable_to_non_nullable
as String,disableUdp: null == disableUdp ? _self.disableUdp : disableUdp // ignore: cast_nullable_to_non_nullable
as bool,includeAll: null == includeAll ? _self.includeAll : includeAll // ignore: cast_nullable_to_non_nullable
as bool,includeAllProxies: null == includeAllProxies ? _self.includeAllProxies : includeAllProxies // ignore: cast_nullable_to_non_nullable
as bool,includeAllProviders: null == includeAllProviders ? _self.includeAllProviders : includeAllProviders // ignore: cast_nullable_to_non_nullable
as bool,strategy: null == strategy ? _self.strategy : strategy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProxyGroupParams].
extension ProxyGroupParamsPatterns on ProxyGroupParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProxyGroupParams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProxyGroupParams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProxyGroupParams value)  $default,){
final _that = this;
switch (_that) {
case _ProxyGroupParams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProxyGroupParams value)?  $default,){
final _that = this;
switch (_that) {
case _ProxyGroupParams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  int? interval,  bool lazy,  int? timeout,  int? maxFailedTimes,  String filter,  String excludeFilter,  String excludeType,  String expectedStatus,  bool hidden,  String icon,  int? tolerance,  String defaultSelected,  String emptyFallback,  bool disableUdp,  bool includeAll,  bool includeAllProxies,  bool includeAllProviders,  String strategy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProxyGroupParams() when $default != null:
return $default(_that.url,_that.interval,_that.lazy,_that.timeout,_that.maxFailedTimes,_that.filter,_that.excludeFilter,_that.excludeType,_that.expectedStatus,_that.hidden,_that.icon,_that.tolerance,_that.defaultSelected,_that.emptyFallback,_that.disableUdp,_that.includeAll,_that.includeAllProxies,_that.includeAllProviders,_that.strategy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  int? interval,  bool lazy,  int? timeout,  int? maxFailedTimes,  String filter,  String excludeFilter,  String excludeType,  String expectedStatus,  bool hidden,  String icon,  int? tolerance,  String defaultSelected,  String emptyFallback,  bool disableUdp,  bool includeAll,  bool includeAllProxies,  bool includeAllProviders,  String strategy)  $default,) {final _that = this;
switch (_that) {
case _ProxyGroupParams():
return $default(_that.url,_that.interval,_that.lazy,_that.timeout,_that.maxFailedTimes,_that.filter,_that.excludeFilter,_that.excludeType,_that.expectedStatus,_that.hidden,_that.icon,_that.tolerance,_that.defaultSelected,_that.emptyFallback,_that.disableUdp,_that.includeAll,_that.includeAllProxies,_that.includeAllProviders,_that.strategy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  int? interval,  bool lazy,  int? timeout,  int? maxFailedTimes,  String filter,  String excludeFilter,  String excludeType,  String expectedStatus,  bool hidden,  String icon,  int? tolerance,  String defaultSelected,  String emptyFallback,  bool disableUdp,  bool includeAll,  bool includeAllProxies,  bool includeAllProviders,  String strategy)?  $default,) {final _that = this;
switch (_that) {
case _ProxyGroupParams() when $default != null:
return $default(_that.url,_that.interval,_that.lazy,_that.timeout,_that.maxFailedTimes,_that.filter,_that.excludeFilter,_that.excludeType,_that.expectedStatus,_that.hidden,_that.icon,_that.tolerance,_that.defaultSelected,_that.emptyFallback,_that.disableUdp,_that.includeAll,_that.includeAllProxies,_that.includeAllProviders,_that.strategy);case _:
  return null;

}
}

}

/// @nodoc


class _ProxyGroupParams implements ProxyGroupParams {
  const _ProxyGroupParams({this.url = '', this.interval, this.lazy = true, this.timeout, this.maxFailedTimes, this.filter = '', this.excludeFilter = '', this.excludeType = '', this.expectedStatus = '', this.hidden = false, this.icon = '', this.tolerance, this.defaultSelected = '', this.emptyFallback = '', this.disableUdp = false, this.includeAll = false, this.includeAllProxies = false, this.includeAllProviders = false, this.strategy = ''});
  

@override@JsonKey() final  String url;
@override final  int? interval;
@override@JsonKey() final  bool lazy;
@override final  int? timeout;
@override final  int? maxFailedTimes;
@override@JsonKey() final  String filter;
@override@JsonKey() final  String excludeFilter;
@override@JsonKey() final  String excludeType;
@override@JsonKey() final  String expectedStatus;
@override@JsonKey() final  bool hidden;
@override@JsonKey() final  String icon;
@override final  int? tolerance;
@override@JsonKey() final  String defaultSelected;
@override@JsonKey() final  String emptyFallback;
@override@JsonKey() final  bool disableUdp;
@override@JsonKey() final  bool includeAll;
@override@JsonKey() final  bool includeAllProxies;
@override@JsonKey() final  bool includeAllProviders;
@override@JsonKey() final  String strategy;

/// Create a copy of ProxyGroupParams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProxyGroupParamsCopyWith<_ProxyGroupParams> get copyWith => __$ProxyGroupParamsCopyWithImpl<_ProxyGroupParams>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProxyGroupParams&&(identical(other.url, url) || other.url == url)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.lazy, lazy) || other.lazy == lazy)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.maxFailedTimes, maxFailedTimes) || other.maxFailedTimes == maxFailedTimes)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.excludeFilter, excludeFilter) || other.excludeFilter == excludeFilter)&&(identical(other.excludeType, excludeType) || other.excludeType == excludeType)&&(identical(other.expectedStatus, expectedStatus) || other.expectedStatus == expectedStatus)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.tolerance, tolerance) || other.tolerance == tolerance)&&(identical(other.defaultSelected, defaultSelected) || other.defaultSelected == defaultSelected)&&(identical(other.emptyFallback, emptyFallback) || other.emptyFallback == emptyFallback)&&(identical(other.disableUdp, disableUdp) || other.disableUdp == disableUdp)&&(identical(other.includeAll, includeAll) || other.includeAll == includeAll)&&(identical(other.includeAllProxies, includeAllProxies) || other.includeAllProxies == includeAllProxies)&&(identical(other.includeAllProviders, includeAllProviders) || other.includeAllProviders == includeAllProviders)&&(identical(other.strategy, strategy) || other.strategy == strategy));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,url,interval,lazy,timeout,maxFailedTimes,filter,excludeFilter,excludeType,expectedStatus,hidden,icon,tolerance,defaultSelected,emptyFallback,disableUdp,includeAll,includeAllProxies,includeAllProviders,strategy]);
}

@override
String toString() {
    return 'ProxyGroupParams(url: $url, interval: $interval, lazy: $lazy, timeout: $timeout, maxFailedTimes: $maxFailedTimes, filter: $filter, excludeFilter: $excludeFilter, excludeType: $excludeType, expectedStatus: $expectedStatus, hidden: $hidden, icon: $icon, tolerance: $tolerance, defaultSelected: $defaultSelected, emptyFallback: $emptyFallback, disableUdp: $disableUdp, includeAll: $includeAll, includeAllProxies: $includeAllProxies, includeAllProviders: $includeAllProviders, strategy: $strategy)';
}


}

/// @nodoc
abstract mixin class _$ProxyGroupParamsCopyWith<$Res> implements $ProxyGroupParamsCopyWith<$Res> {
  factory _$ProxyGroupParamsCopyWith(_ProxyGroupParams value, $Res Function(_ProxyGroupParams) _then) = __$ProxyGroupParamsCopyWithImpl;
@override @useResult
$Res call({
 String url, int? interval, bool lazy, int? timeout, int? maxFailedTimes, String filter, String excludeFilter, String excludeType, String expectedStatus, bool hidden, String icon, int? tolerance, String defaultSelected, String emptyFallback, bool disableUdp, bool includeAll, bool includeAllProxies, bool includeAllProviders, String strategy
});




}
/// @nodoc
class __$ProxyGroupParamsCopyWithImpl<$Res>
    implements _$ProxyGroupParamsCopyWith<$Res> {
  __$ProxyGroupParamsCopyWithImpl(this._self, this._then);

  final _ProxyGroupParams _self;
  final $Res Function(_ProxyGroupParams) _then;

/// Create a copy of ProxyGroupParams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? interval = freezed,Object? lazy = null,Object? timeout = freezed,Object? maxFailedTimes = freezed,Object? filter = null,Object? excludeFilter = null,Object? excludeType = null,Object? expectedStatus = null,Object? hidden = null,Object? icon = null,Object? tolerance = freezed,Object? defaultSelected = null,Object? emptyFallback = null,Object? disableUdp = null,Object? includeAll = null,Object? includeAllProxies = null,Object? includeAllProviders = null,Object? strategy = null,}) {
  return _then(_ProxyGroupParams(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,interval: freezed == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int?,lazy: null == lazy ? _self.lazy : lazy // ignore: cast_nullable_to_non_nullable
as bool,timeout: freezed == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as int?,maxFailedTimes: freezed == maxFailedTimes ? _self.maxFailedTimes : maxFailedTimes // ignore: cast_nullable_to_non_nullable
as int?,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String,excludeFilter: null == excludeFilter ? _self.excludeFilter : excludeFilter // ignore: cast_nullable_to_non_nullable
as String,excludeType: null == excludeType ? _self.excludeType : excludeType // ignore: cast_nullable_to_non_nullable
as String,expectedStatus: null == expectedStatus ? _self.expectedStatus : expectedStatus // ignore: cast_nullable_to_non_nullable
as String,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,tolerance: freezed == tolerance ? _self.tolerance : tolerance // ignore: cast_nullable_to_non_nullable
as int?,defaultSelected: null == defaultSelected ? _self.defaultSelected : defaultSelected // ignore: cast_nullable_to_non_nullable
as String,emptyFallback: null == emptyFallback ? _self.emptyFallback : emptyFallback // ignore: cast_nullable_to_non_nullable
as String,disableUdp: null == disableUdp ? _self.disableUdp : disableUdp // ignore: cast_nullable_to_non_nullable
as bool,includeAll: null == includeAll ? _self.includeAll : includeAll // ignore: cast_nullable_to_non_nullable
as bool,includeAllProxies: null == includeAllProxies ? _self.includeAllProxies : includeAllProxies // ignore: cast_nullable_to_non_nullable
as bool,includeAllProviders: null == includeAllProviders ? _self.includeAllProviders : includeAllProviders // ignore: cast_nullable_to_non_nullable
as bool,strategy: null == strategy ? _self.strategy : strategy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

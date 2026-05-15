// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'canvas_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CanvasModel {

 String get id; String get title; int get order; double get tempo; String get timeSignature; String get type; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of CanvasModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanvasModelCopyWith<CanvasModel> get copyWith => _$CanvasModelCopyWithImpl<CanvasModel>(this as CanvasModel, _$identity);

  /// Serializes this CanvasModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanvasModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.tempo, tempo) || other.tempo == tempo)&&(identical(other.timeSignature, timeSignature) || other.timeSignature == timeSignature)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,order,tempo,timeSignature,type,createdAt,updatedAt);

@override
String toString() {
  return 'CanvasModel(id: $id, title: $title, order: $order, tempo: $tempo, timeSignature: $timeSignature, type: $type, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CanvasModelCopyWith<$Res>  {
  factory $CanvasModelCopyWith(CanvasModel value, $Res Function(CanvasModel) _then) = _$CanvasModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, int order, double tempo, String timeSignature, String type, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$CanvasModelCopyWithImpl<$Res>
    implements $CanvasModelCopyWith<$Res> {
  _$CanvasModelCopyWithImpl(this._self, this._then);

  final CanvasModel _self;
  final $Res Function(CanvasModel) _then;

/// Create a copy of CanvasModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? order = null,Object? tempo = null,Object? timeSignature = null,Object? type = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,tempo: null == tempo ? _self.tempo : tempo // ignore: cast_nullable_to_non_nullable
as double,timeSignature: null == timeSignature ? _self.timeSignature : timeSignature // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CanvasModel].
extension CanvasModelPatterns on CanvasModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanvasModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanvasModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanvasModel value)  $default,){
final _that = this;
switch (_that) {
case _CanvasModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanvasModel value)?  $default,){
final _that = this;
switch (_that) {
case _CanvasModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  int order,  double tempo,  String timeSignature,  String type,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanvasModel() when $default != null:
return $default(_that.id,_that.title,_that.order,_that.tempo,_that.timeSignature,_that.type,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  int order,  double tempo,  String timeSignature,  String type,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CanvasModel():
return $default(_that.id,_that.title,_that.order,_that.tempo,_that.timeSignature,_that.type,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  int order,  double tempo,  String timeSignature,  String type,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CanvasModel() when $default != null:
return $default(_that.id,_that.title,_that.order,_that.tempo,_that.timeSignature,_that.type,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CanvasModel implements CanvasModel {
  const _CanvasModel({required this.id, required this.title, required this.order, required this.tempo, required this.timeSignature, this.type = 'manual', this.createdAt, this.updatedAt});
  factory _CanvasModel.fromJson(Map<String, dynamic> json) => _$CanvasModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  int order;
@override final  double tempo;
@override final  String timeSignature;
@override@JsonKey() final  String type;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of CanvasModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanvasModelCopyWith<_CanvasModel> get copyWith => __$CanvasModelCopyWithImpl<_CanvasModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CanvasModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanvasModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.tempo, tempo) || other.tempo == tempo)&&(identical(other.timeSignature, timeSignature) || other.timeSignature == timeSignature)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,order,tempo,timeSignature,type,createdAt,updatedAt);

@override
String toString() {
  return 'CanvasModel(id: $id, title: $title, order: $order, tempo: $tempo, timeSignature: $timeSignature, type: $type, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CanvasModelCopyWith<$Res> implements $CanvasModelCopyWith<$Res> {
  factory _$CanvasModelCopyWith(_CanvasModel value, $Res Function(_CanvasModel) _then) = __$CanvasModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, int order, double tempo, String timeSignature, String type, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$CanvasModelCopyWithImpl<$Res>
    implements _$CanvasModelCopyWith<$Res> {
  __$CanvasModelCopyWithImpl(this._self, this._then);

  final _CanvasModel _self;
  final $Res Function(_CanvasModel) _then;

/// Create a copy of CanvasModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? order = null,Object? tempo = null,Object? timeSignature = null,Object? type = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_CanvasModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,tempo: null == tempo ? _self.tempo : tempo // ignore: cast_nullable_to_non_nullable
as double,timeSignature: null == timeSignature ? _self.timeSignature : timeSignature // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

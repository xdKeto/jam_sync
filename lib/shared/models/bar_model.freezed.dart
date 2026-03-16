// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bar_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BarModel {

 String get id; int get index; List<String> get chords; DateTime? get updatedAt; String? get updatedBy;
/// Create a copy of BarModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BarModelCopyWith<BarModel> get copyWith => _$BarModelCopyWithImpl<BarModel>(this as BarModel, _$identity);

  /// Serializes this BarModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BarModel&&(identical(other.id, id) || other.id == id)&&(identical(other.index, index) || other.index == index)&&const DeepCollectionEquality().equals(other.chords, chords)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,index,const DeepCollectionEquality().hash(chords),updatedAt,updatedBy);

@override
String toString() {
  return 'BarModel(id: $id, index: $index, chords: $chords, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $BarModelCopyWith<$Res>  {
  factory $BarModelCopyWith(BarModel value, $Res Function(BarModel) _then) = _$BarModelCopyWithImpl;
@useResult
$Res call({
 String id, int index, List<String> chords, DateTime? updatedAt, String? updatedBy
});




}
/// @nodoc
class _$BarModelCopyWithImpl<$Res>
    implements $BarModelCopyWith<$Res> {
  _$BarModelCopyWithImpl(this._self, this._then);

  final BarModel _self;
  final $Res Function(BarModel) _then;

/// Create a copy of BarModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? index = null,Object? chords = null,Object? updatedAt = freezed,Object? updatedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,chords: null == chords ? _self.chords : chords // ignore: cast_nullable_to_non_nullable
as List<String>,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BarModel].
extension BarModelPatterns on BarModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BarModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BarModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BarModel value)  $default,){
final _that = this;
switch (_that) {
case _BarModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BarModel value)?  $default,){
final _that = this;
switch (_that) {
case _BarModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int index,  List<String> chords,  DateTime? updatedAt,  String? updatedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BarModel() when $default != null:
return $default(_that.id,_that.index,_that.chords,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int index,  List<String> chords,  DateTime? updatedAt,  String? updatedBy)  $default,) {final _that = this;
switch (_that) {
case _BarModel():
return $default(_that.id,_that.index,_that.chords,_that.updatedAt,_that.updatedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int index,  List<String> chords,  DateTime? updatedAt,  String? updatedBy)?  $default,) {final _that = this;
switch (_that) {
case _BarModel() when $default != null:
return $default(_that.id,_that.index,_that.chords,_that.updatedAt,_that.updatedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BarModel implements BarModel {
  const _BarModel({required this.id, required this.index, required final  List<String> chords, this.updatedAt, this.updatedBy}): _chords = chords;
  factory _BarModel.fromJson(Map<String, dynamic> json) => _$BarModelFromJson(json);

@override final  String id;
@override final  int index;
 final  List<String> _chords;
@override List<String> get chords {
  if (_chords is EqualUnmodifiableListView) return _chords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chords);
}

@override final  DateTime? updatedAt;
@override final  String? updatedBy;

/// Create a copy of BarModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BarModelCopyWith<_BarModel> get copyWith => __$BarModelCopyWithImpl<_BarModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BarModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BarModel&&(identical(other.id, id) || other.id == id)&&(identical(other.index, index) || other.index == index)&&const DeepCollectionEquality().equals(other._chords, _chords)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,index,const DeepCollectionEquality().hash(_chords),updatedAt,updatedBy);

@override
String toString() {
  return 'BarModel(id: $id, index: $index, chords: $chords, updatedAt: $updatedAt, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$BarModelCopyWith<$Res> implements $BarModelCopyWith<$Res> {
  factory _$BarModelCopyWith(_BarModel value, $Res Function(_BarModel) _then) = __$BarModelCopyWithImpl;
@override @useResult
$Res call({
 String id, int index, List<String> chords, DateTime? updatedAt, String? updatedBy
});




}
/// @nodoc
class __$BarModelCopyWithImpl<$Res>
    implements _$BarModelCopyWith<$Res> {
  __$BarModelCopyWithImpl(this._self, this._then);

  final _BarModel _self;
  final $Res Function(_BarModel) _then;

/// Create a copy of BarModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? index = null,Object? chords = null,Object? updatedAt = freezed,Object? updatedBy = freezed,}) {
  return _then(_BarModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,chords: null == chords ? _self._chords : chords // ignore: cast_nullable_to_non_nullable
as List<String>,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

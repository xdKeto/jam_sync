// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'section_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SectionModel {

 String get id; String get name; int get order; int get barCount; int get startBar;
/// Create a copy of SectionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SectionModelCopyWith<SectionModel> get copyWith => _$SectionModelCopyWithImpl<SectionModel>(this as SectionModel, _$identity);

  /// Serializes this SectionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SectionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&(identical(other.barCount, barCount) || other.barCount == barCount)&&(identical(other.startBar, startBar) || other.startBar == startBar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,order,barCount,startBar);

@override
String toString() {
  return 'SectionModel(id: $id, name: $name, order: $order, barCount: $barCount, startBar: $startBar)';
}


}

/// @nodoc
abstract mixin class $SectionModelCopyWith<$Res>  {
  factory $SectionModelCopyWith(SectionModel value, $Res Function(SectionModel) _then) = _$SectionModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, int order, int barCount, int startBar
});




}
/// @nodoc
class _$SectionModelCopyWithImpl<$Res>
    implements $SectionModelCopyWith<$Res> {
  _$SectionModelCopyWithImpl(this._self, this._then);

  final SectionModel _self;
  final $Res Function(SectionModel) _then;

/// Create a copy of SectionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? order = null,Object? barCount = null,Object? startBar = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,barCount: null == barCount ? _self.barCount : barCount // ignore: cast_nullable_to_non_nullable
as int,startBar: null == startBar ? _self.startBar : startBar // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SectionModel].
extension SectionModelPatterns on SectionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SectionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SectionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SectionModel value)  $default,){
final _that = this;
switch (_that) {
case _SectionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SectionModel value)?  $default,){
final _that = this;
switch (_that) {
case _SectionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int order,  int barCount,  int startBar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SectionModel() when $default != null:
return $default(_that.id,_that.name,_that.order,_that.barCount,_that.startBar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int order,  int barCount,  int startBar)  $default,) {final _that = this;
switch (_that) {
case _SectionModel():
return $default(_that.id,_that.name,_that.order,_that.barCount,_that.startBar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int order,  int barCount,  int startBar)?  $default,) {final _that = this;
switch (_that) {
case _SectionModel() when $default != null:
return $default(_that.id,_that.name,_that.order,_that.barCount,_that.startBar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SectionModel implements SectionModel {
  const _SectionModel({required this.id, required this.name, required this.order, required this.barCount, required this.startBar});
  factory _SectionModel.fromJson(Map<String, dynamic> json) => _$SectionModelFromJson(json);

@override final  String id;
@override final  String name;
@override final  int order;
@override final  int barCount;
@override final  int startBar;

/// Create a copy of SectionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SectionModelCopyWith<_SectionModel> get copyWith => __$SectionModelCopyWithImpl<_SectionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SectionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SectionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&(identical(other.barCount, barCount) || other.barCount == barCount)&&(identical(other.startBar, startBar) || other.startBar == startBar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,order,barCount,startBar);

@override
String toString() {
  return 'SectionModel(id: $id, name: $name, order: $order, barCount: $barCount, startBar: $startBar)';
}


}

/// @nodoc
abstract mixin class _$SectionModelCopyWith<$Res> implements $SectionModelCopyWith<$Res> {
  factory _$SectionModelCopyWith(_SectionModel value, $Res Function(_SectionModel) _then) = __$SectionModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int order, int barCount, int startBar
});




}
/// @nodoc
class __$SectionModelCopyWithImpl<$Res>
    implements _$SectionModelCopyWith<$Res> {
  __$SectionModelCopyWithImpl(this._self, this._then);

  final _SectionModel _self;
  final $Res Function(_SectionModel) _then;

/// Create a copy of SectionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? order = null,Object? barCount = null,Object? startBar = null,}) {
  return _then(_SectionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,barCount: null == barCount ? _self.barCount : barCount // ignore: cast_nullable_to_non_nullable
as int,startBar: null == startBar ? _self.startBar : startBar // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

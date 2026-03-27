// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bar_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BarModel _$BarModelFromJson(Map<String, dynamic> json) => _BarModel(
  id: json['id'] as String,
  index: (json['index'] as num).toInt(),
  chords: (json['chords'] as List<dynamic>).map((e) => e as String).toList(),
  passingChord:
      (json['passingChord'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  beatCount: (json['beatCount'] as num?)?.toInt(),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  updatedBy: json['updatedBy'] as String?,
);

Map<String, dynamic> _$BarModelToJson(_BarModel instance) => <String, dynamic>{
  'id': instance.id,
  'index': instance.index,
  'chords': instance.chords,
  'passingChord': instance.passingChord,
  'beatCount': instance.beatCount,
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'updatedBy': instance.updatedBy,
};

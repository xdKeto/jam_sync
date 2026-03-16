// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SectionModel _$SectionModelFromJson(Map<String, dynamic> json) =>
    _SectionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      order: (json['order'] as num).toInt(),
      barCount: (json['barCount'] as num).toInt(),
      startBar: (json['startBar'] as num).toInt(),
    );

Map<String, dynamic> _$SectionModelToJson(_SectionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'order': instance.order,
      'barCount': instance.barCount,
      'startBar': instance.startBar,
    };

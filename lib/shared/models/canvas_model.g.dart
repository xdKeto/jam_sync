// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CanvasModel _$CanvasModelFromJson(Map<String, dynamic> json) => _CanvasModel(
  id: json['id'] as String,
  title: json['title'] as String,
  order: (json['order'] as num).toInt(),
  tempo: (json['tempo'] as num).toDouble(),
  timeSignature: json['timeSignature'] as String,
  type: json['type'] as String? ?? 'manual',
  audioUrl: json['audioUrl'] as String?,
  extractionStatus: json['extractionStatus'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CanvasModelToJson(_CanvasModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'order': instance.order,
      'tempo': instance.tempo,
      'timeSignature': instance.timeSignature,
      'type': instance.type,
      'audioUrl': instance.audioUrl,
      'extractionStatus': instance.extractionStatus,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

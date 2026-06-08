// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NoteModel _$NoteModelFromJson(Map<String, dynamic> json) => _NoteModel(
  id: json['id'] as String,
  text: json['text'] as String,
  posX: (json['posX'] as num).toDouble(),
  posY: (json['posY'] as num).toDouble(),
  createdBy: json['createdBy'] as String,
);

Map<String, dynamic> _$NoteModelToJson(_NoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'posX': instance.posX,
      'posY': instance.posY,
      'createdBy': instance.createdBy,
    };

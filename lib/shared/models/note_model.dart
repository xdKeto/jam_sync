import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_model.freezed.dart';
part 'note_model.g.dart';

@freezed
abstract class NoteModel with _$NoteModel {
  const factory NoteModel({
    required String id,
    required String text,
    required double posX,
    required double posY,
    required String createdBy,
  }) = _NoteModel;

  factory NoteModel.fromJson(Map<String, dynamic> json) => _$NoteModelFromJson(json);

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      text: data['text'] as String,
      posX: (data['posX'] as num).toDouble(),
      posY: (data['posY'] as num).toDouble(),
      createdBy: data['createdBy'] as String,
    );
  }
}
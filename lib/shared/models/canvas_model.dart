import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'canvas_model.freezed.dart';
part 'canvas_model.g.dart';

@freezed
abstract class CanvasModel with _$CanvasModel {
  const factory CanvasModel({
    required String id,
    required String title,
    required int order,
    required double tempo,
    required String timeSignature,
    @Default('manual') String type,
    String? audioUrl,
    String? extractionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CanvasModel;

  factory CanvasModel.fromJson(Map<String, dynamic> json) =>
      _$CanvasModelFromJson(json);

  factory CanvasModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CanvasModel(
      id: doc.id,
      title: data['title'] as String,
      order: data['order'] as int,
      tempo: (data['tempo'] as num).toDouble(),
      timeSignature: data['timeSignature'] as String,
      type: data['type'] as String? ?? 'manual',
      audioUrl: data['audioUrl'] as String?,
      extractionStatus: data['extractionStatus'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

Map<String, dynamic> canvasToFirestore(CanvasModel canvas) {
  return {
    'title': canvas.title,
    'order': canvas.order,
    'tempo': canvas.tempo,
    'timeSignature': canvas.timeSignature,
    'type': canvas.type,
    'audioUrl': canvas.audioUrl,
    'extractionStatus': canvas.extractionStatus,
  };
}

int beatsPerBar(String timeSignature) {
  switch (timeSignature) {
    case '2/4':
      return 2;
    case '3/4':
      return 3;
    case '4/4':
      return 4;
    case '6/8':
      return 6;
    default:
      return 4;
  }
}

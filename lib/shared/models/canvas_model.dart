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
  };
}

// helper time signature
int beatsPerBar(String timeSignature) {
  final parts = timeSignature.split('/');
  if (parts.length != 2) return 4;

  final numerator = int.tryParse(parts[0]) ?? 4;
  final denominator = int.tryParse(parts[1]) ?? 4;

  // case 6/8, 9/8, 12/8 -> modulus 3
  if (denominator == 8 && numerator % 3 == 0) {
    return numerator ~/ 3;
  }

  return numerator;
}

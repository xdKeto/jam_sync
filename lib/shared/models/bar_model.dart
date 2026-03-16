import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bar_model.freezed.dart';
part 'bar_model.g.dart';

@freezed
abstract class BarModel with _$BarModel {
  const factory BarModel({
    required String id,
    required int index,
    required List<String> chords,
    DateTime? updatedAt,
    String? updatedBy,
  }) = _BarModel;

  factory BarModel.fromJson(Map<String, dynamic> json) =>
      _$BarModelFromJson(json);

  factory BarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BarModel(
      id: doc.id,
      index: data['index'] as int,
      chords: List<String>.from(data['chords'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] as String?,
    );
  }
}

Map<String, dynamic> barToFirestore(BarModel bar) {
  return {
    'index': bar.index,
    'chords': bar.chords,
    'updatedBy': bar.updatedBy,
  };
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'section_model.freezed.dart';
part 'section_model.g.dart';

@freezed
abstract class SectionModel with _$SectionModel {
  const factory SectionModel({
    required String id,
    required String name,
    required int order,
    required int barCount,
    required int startBar,
  }) = _SectionModel;

  factory SectionModel.fromJson(Map<String, dynamic> json) =>
      _$SectionModelFromJson(json);

  factory SectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SectionModel.fromJson({'id': doc.id, ...data});
  }
}

Map<String, dynamic> sectionToFirestore(SectionModel section) {
  final json = section.toJson();
  json.remove('id');
  return json;
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_model.freezed.dart';
part 'project_model.g.dart';

@freezed
abstract class ProjectModel with _$ProjectModel {
  const factory ProjectModel({
    required String id,
    required String title,
    required String createdBy,
    required String roomCode,
    @Default([]) List<String> participants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ProjectModel;

  factory ProjectModel.fromJson(Map<String, dynamic> json) =>
      _$ProjectModelFromJson(json);

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      title: data['title'] as String,
      createdBy: data['createdBy'] as String,
      roomCode: data['roomCode'] as String,
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

Map<String, dynamic> projectToFirestore(ProjectModel project) {
  return {
    'title': project.title,
    'createdBy': project.createdBy,
    'roomCode': project.roomCode,
    'participants': project.participants,
  };
}

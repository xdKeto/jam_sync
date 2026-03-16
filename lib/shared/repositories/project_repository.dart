import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:jam_sync/shared/models/project_model.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/models/bar_model.dart';

class ProjectRepository {
  final FirebaseFirestore _firestore;

  ProjectRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _projectsRef => _firestore.collection('projects');

  String _generateRoomCode() {
    final uuid = const Uuid().v4();
    final hash = uuid.hashCode.abs();
    return (hash % 900000 + 100000).toString();
  }

  Future<String> createProject({
    required String title,
    required String songTitle,
    required double tempo,
    required String timeSignature,
    required bool useTemplate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final projectRef = _projectsRef.doc();
    final projectId = projectRef.id;

    final project = ProjectModel(
      id: projectId,
      title: title,
      createdBy: user.uid,
      roomCode: _generateRoomCode(),
      participants: [user.uid],
    );

    final batch = _firestore.batch();

    batch.set(projectRef, {
      ...projectToFirestore(project),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final canvasRef = projectRef.collection('canvases').doc();
    final canvas = CanvasModel(
      id: canvasRef.id,
      title: songTitle.isNotEmpty ? songTitle : 'Untitled',
      order: 0,
      tempo: tempo,
      timeSignature: timeSignature,
      type: 'manual',
    );

    batch.set(canvasRef, {
      ...canvasToFirestore(canvas),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (useTemplate) {
      _addTemplateSections(batch, canvasRef, timeSignature);
    }

    await batch.commit();
    return projectId;
  }

  void _addTemplateSections(
    WriteBatch batch,
    DocumentReference canvasRef,
    String timeSignature,
  ) {
    final slots = beatsPerBar(timeSignature);
    final emptyChords = List.filled(slots, '');

    final sections = [
      {'name': 'Verse 1', 'order': 0, 'barCount': 16, 'startBar': 0},
      {'name': 'Chorus', 'order': 1, 'barCount': 16, 'startBar': 16},
    ];

    for (final sectionData in sections) {
      final sectionRef = canvasRef.collection('sections').doc();
      final section = SectionModel(
        id: sectionRef.id,
        name: sectionData['name'] as String,
        order: sectionData['order'] as int,
        barCount: sectionData['barCount'] as int,
        startBar: sectionData['startBar'] as int,
      );

      batch.set(sectionRef, sectionToFirestore(section));

      final barCount = sectionData['barCount'] as int;
      final startBar = sectionData['startBar'] as int;

      for (int i = 0; i < barCount; i++) {
        final barRef = sectionRef.collection('bars').doc();
        final bar = BarModel(
          id: barRef.id,
          index: startBar + i,
          chords: List.from(emptyChords),
        );

        batch.set(barRef, {
          ...barToFirestore(bar),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<List<ProjectModel>> getUserProjects() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final snapshot = await _projectsRef
        .where('participants', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProjectModel.fromFirestore(doc))
        .toList();
  }

  Future<ProjectModel> getProject(String projectId) async {
    final doc = await _projectsRef.doc(projectId).get();
    if (!doc.exists) throw Exception('Project not found');
    return ProjectModel.fromFirestore(doc);
  }

  Future<void> deleteProject(String projectId) async {
    await _projectsRef.doc(projectId).delete();
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

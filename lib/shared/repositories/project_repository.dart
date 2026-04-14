import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:jam_sync/shared/models/project_model.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/models/bar_model.dart';

class ProjectRepository {
  final FirebaseFirestore _firestore;

  ProjectRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _projectsRef => _firestore.collection('projects');

  String generateRoomCode() {
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
      roomCode: generateRoomCode(),
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
      addTemplateSections(batch, canvasRef, timeSignature);
    }

    await batch.commit();
    return projectId;
  }

  void addTemplateSections(WriteBatch batch, DocumentReference canvasRef, String timeSignature) {
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
        final bar = BarModel(id: barRef.id, index: startBar + i, chords: List.from(emptyChords));

        batch.set(barRef, {...barToFirestore(bar), 'updatedAt': FieldValue.serverTimestamp()});
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

    return snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
  }

  Future<ProjectModel> getProject(String projectId) async {
    final doc = await _projectsRef.doc(projectId).get();
    if (!doc.exists) throw Exception('Project not found');
    return ProjectModel.fromFirestore(doc);
  }

  Stream<ProjectModel> streamProject(String projectId) {
    return _projectsRef.doc(projectId).snapshots().map((doc) {
      if (!doc.exists) throw Exception('Project not found');
      return ProjectModel.fromFirestore(doc);
    });
  }

  Stream<List<CanvasModel>> streamCanvases(String projectId) {
    return _projectsRef
        .doc(projectId)
        .collection('canvases')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CanvasModel.fromFirestore(doc)).toList())
        .handleError((_) {});
  }

  Stream<List<SectionModel>> streamSections(String projectId, String canvasId) {
    return _projectsRef
        .doc(projectId)
        .collection('canvases')
        .doc(canvasId)
        .collection('sections')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SectionModel.fromFirestore(doc)).toList());
  }

  Stream<List<BarModel>> streamBars(String projectId, String canvasId, String sectionId) {
    return _projectsRef
        .doc(projectId)
        .collection('canvases')
        .doc(canvasId)
        .collection('sections')
        .doc(sectionId)
        .collection('bars')
        .orderBy('index')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => BarModel.fromFirestore(doc)).toList());
  }

  Future<List<CanvasModel>> getCanvases(String projectId) async {
    final snapshot = await _projectsRef
        .doc(projectId)
        .collection('canvases')
        .orderBy('order')
        .get();
    return snapshot.docs.map((doc) => CanvasModel.fromFirestore(doc)).toList();
  }

  Future<ProjectModel> joinRoom(String roomCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final snapshot = await _projectsRef
        .where('roomCode', isEqualTo: roomCode.trim())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) throw Exception('Room not found');

    final doc = snapshot.docs.first;
    final project = ProjectModel.fromFirestore(doc);

    if (project.participants.contains(user.uid)) {
      throw Exception('You are already a participant of this project');
    }

    await doc.reference.update({
      'participants': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return project;
  }

  Future<void> deleteProject(String projectId) async {
    final doc = await _projectsRef.doc(projectId).get();
    if (doc.exists) {
      final project = ProjectModel.fromFirestore(doc);
      final roomCode = project.roomCode;

      final rtdb = FirebaseDatabase.instance.ref();
      await rtdb.child('rooms/$roomCode').remove();
      await rtdb.child('playback_sessions/$projectId').remove();
    }
    await _projectsRef.doc(projectId).delete();
  }

  // chord stuff
  Future<void> updateBarChord({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required String barID,
    required int beatIndex,
    required String chord,
    required String userID,
  }) async {
    final barRef = _projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc(sectionID)
        .collection('bars')
        .doc(barID);

    final doc = await barRef.get();
    final chords = List<String>.from(doc.data()?['chords'] ?? []);
    if (beatIndex < chords.length) chords[beatIndex] = chord;

    await barRef.update({
      'chords': chords,
      'updatedBy': userID,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBarChord({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required String barID,
    required int beatIndex,
    required String userID,
  }) async {
    final barRef = _projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc(sectionID)
        .collection('bars')
        .doc(barID);

    final doc = await barRef.get();
    final chords = List<String>.from(doc.data()?['chords'] ?? []);
    if (beatIndex < chords.length) chords[beatIndex] = '';

    await barRef.update({
      'chords': chords,
      'updatedBy': userID,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePassingChord({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required String barID,
    required int beatIndex,
    required String chord,
    required String userID,
  }) async {
    final barRef = _projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc(sectionID)
        .collection('bars')
        .doc(barID);

    final doc = await barRef.get();
    final chords = List<String>.from(doc.data()?['passingChord'] ?? []);
    final mainChords = List<dynamic>.from(doc.data()?['chords'] ?? []);
    final targetLength = mainChords.length > beatIndex ? mainChords.length : beatIndex + 1;

    while (chords.length < targetLength) {
      chords.add('');
    }

    chords[beatIndex] = chord;

    await barRef.update({
      'passingChord': chords,
      'updatedBy': userID,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePassingChord({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required String barID,
    required int beatIndex,
    required String userID,
  }) async {
    final barRef = _projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc(sectionID)
        .collection('bars')
        .doc(barID);

    final doc = await barRef.get();
    final chords = List<String>.from(doc.data()?['passingChord'] ?? []);
    final mainChords = List<dynamic>.from(doc.data()?['chords'] ?? []);
    final targetLength = mainChords.length > beatIndex ? mainChords.length : beatIndex + 1;

    while (chords.length < targetLength) {
      chords.add('');
    }

    chords[beatIndex] = '';

    await barRef.update({
      'passingChord': chords,
      'updatedBy': userID,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // section steuff
  Future<void> addSection({
    required String projectID,
    required String canvasID,
    required String name,
    required int order,
    required int barCount,
    required int startBar,
    required String timeSignature,
  }) async {
    final batch = _firestore.batch();
    final sectionRef = _projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc();

    batch.set(
      sectionRef,
      sectionToFirestore(
        SectionModel(
          id: sectionRef.id,
          name: name,
          order: order,
          barCount: barCount,
          startBar: startBar,
        ),
      ),
    );

    // bar kosong
    final slot = beatsPerBar(timeSignature);
    final empty = List.filled(slot, '');

    for (int i = 0; i < barCount; i++) {
      final barRef = sectionRef.collection('bars').doc();
      batch.set(barRef, {
        ...barToFirestore(BarModel(id: barRef.id, index: startBar + i, chords: List.from(empty))),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> updateSection({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required Map<String, dynamic> data,
  }) async {
    await _projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc(sectionID)
        .update(data);
  }

  Future<void> deleteSection({
    required String projectID,
    required String canvasID,
    required String sectionID,
  }) async {
    final sectionRef = _projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc(sectionID);

    final barSnap = await sectionRef.collection('bars').get();
    final batch = _firestore.batch();

    for (final doc in barSnap.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(sectionRef);
    await batch.commit();
  }

  Future<void> reorderSections({
    required String projectID,
    required String canvasID,
    required List<SectionModel> reordered,
  }) async {
    final batch = _firestore.batch();
    int runningStartBar = 0;
    for (int i = 0; i < reordered.length; i++) {
      final section = reordered[i];
      final ref = _projectsRef
          .doc(projectID)
          .collection('canvases')
          .doc(canvasID)
          .collection('sections')
          .doc(section.id);

      batch.update(ref, {'order': i, 'startBar': runningStartBar});

      runningStartBar += section.barCount;
    }
    await batch.commit();
  }

  Future<void> recalculateSectionMetadata({
    required String projectID,
    required String canvasID,
  }) async {
    final sectionsSnap = await _projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .orderBy('order')
        .get();

    final batch = _firestore.batch();
    int runningStart = 0;

    for (final doc in sectionsSnap.docs) {
      final barsCount = await doc.reference.collection('bars').count().get();
      final count = barsCount.count ?? 0;
      batch.update(doc.reference, {'startBar': runningStart, 'barCount': count});
      runningStart += count;
    }
    await batch.commit();
  }

  //  bar stuefff
  Future<void> addBar({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required int index,
    required int beatCount,
    required String timeSignature,
  }) async {
    final sectionRef = _projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc(sectionID);

    final empty = List.filled(beatCount, '');
    final barRef = sectionRef.collection('bars').doc();

    final batch = _firestore.batch();
    batch.set(barRef, {
      ...barToFirestore(BarModel(id: barRef.id, index: index, chords: empty, beatCount: beatCount)),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(sectionRef, {'barCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> deleteBar({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required String barID,
  }) async {
    final sectionRef = _projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc(sectionID);

    final batch = _firestore.batch();
    batch.delete(sectionRef.collection('bars').doc(barID));
    batch.update(sectionRef, {'barCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<void> reorderBars({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required List<BarModel> reordered,
  }) async {
    final batch = _firestore.batch();
    for (int i = 0; i < reordered.length; i++) {
      final bar = reordered[i];
      final ref = _projectsRef
          .doc(projectID)
          .collection('canvases')
          .doc(canvasID)
          .collection('sections')
          .doc(sectionID)
          .collection('bars')
          .doc(bar.id);

      batch.update(ref, {'index': i});
    }
    await batch.commit();
  }

  Future<void> updateBarBeatCount({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required String barID,
    required int newBeatCount,
    required List<String> currentChords,
    required List<String> currentPassing,
    required String userID,
  }) async {
    final barRef = _projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc(sectionID)
        .collection('bars')
        .doc(barID);

    List<String> newChords;
    List<String> newPassing;

    if (newBeatCount > currentChords.length) {
      newChords = [...currentChords, ...List.filled(newBeatCount - currentChords.length, '')];
      newPassing = [...currentPassing, ...List.filled(newBeatCount - currentPassing.length, '')];
    } else {
      newChords = currentChords.sublist(0, newBeatCount);
      newPassing = currentPassing.sublist(0, newBeatCount.clamp(0, currentPassing.length));
    }

    await barRef.update({
      'chords': newChords,
      'passingChord': newPassing,
      'beatCount': newBeatCount,
      'updatedBy': userID,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

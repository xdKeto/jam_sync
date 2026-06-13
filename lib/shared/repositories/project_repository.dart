import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/models/note_model.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:jam_sync/shared/models/project_model.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/models/bar_model.dart';

final forceServerFetch = GetOptions(source: Source.server);

// sistem batching, add banyak, commit firebase
class ProjectRepository {
  final FirebaseFirestore _firestore;

  ProjectRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get projectsRef =>
      _firestore.collection('projects'); //project

  String generateRoomCode() {
    final uuid = const Uuid().v4();
    final hash = uuid.hashCode.abs();
    return (hash % 900000 + 100000).toString();
  }

  // PROJECTS BATCHING
  Future<String> createProject({
    required String title,
    required String songTitle,
    required double tempo,
    required String timeSignature,
    required bool useTemplate,
    Map<String, dynamic>? songTemplate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final projectRef = projectsRef.doc();
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
      if (songTemplate != null) {
        addSongTemplateSections(batch, canvasRef, songTemplate, timeSignature);
      } else {
        addTemplateSections(batch, canvasRef, timeSignature);
      }
    }

    await batch.commit();
    return projectId;
  }

  void addTemplateSections(
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

  void addSongTemplateSections(
    WriteBatch batch,
    DocumentReference canvasRef,
    Map<String, dynamic> songTemplate,
    String timeSignature,
  ) {
    final sections = songTemplate['sections'] as List<dynamic>;

    for (final sectionData in sections) {
      final sectionMap = sectionData as Map<String, dynamic>;
      final bars = sectionMap['bars'] as List<dynamic>;

      final sectionRef = canvasRef.collection('sections').doc();
      final section = SectionModel(
        id: sectionRef.id,
        name: sectionMap['name'] as String,
        order: sectionMap['order'] as int,
        barCount: bars.length,
        startBar: 0,
      );

      batch.set(sectionRef, sectionToFirestore(section));

      for (int i = 0; i < bars.length; i++) {
        final barData = bars[i] as Map<String, dynamic>;
        final barChords = barData['chords'] as List<dynamic>;

        final barRef = sectionRef.collection('bars').doc();
        final bar = BarModel(
          id: barRef.id,
          index: i,
          chords: barChords.map((e) => e.toString()).toList(),
        );

        batch.set(barRef, {
          ...barToFirestore(bar),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // STREAM GET METHODS
  // stream, realtime referenced ke provider
  Future<List<ProjectModel>> getUserProjects() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final snapshot = await projectsRef
        .where('participants', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
  }

  Future<ProjectModel> getProject(String projectId) async {
    final doc = await projectsRef.doc(projectId).get();
    if (!doc.exists) throw Exception('Project not found');
    return ProjectModel.fromFirestore(doc);
  }

  // get snapshots
  Stream<List<CanvasModel>> streamCanvases(String projectId) {
    return projectsRef
        .doc(projectId)
        .collection('canvases')
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CanvasModel.fromFirestore(doc))
              .toList(),
        )
        .handleError((_) {});
  }

  Stream<List<SectionModel>> streamSections(String projectId, String canvasId) {
    return projectsRef
        .doc(projectId)
        .collection('canvases')
        .doc(canvasId)
        .collection('sections')
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SectionModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<List<SectionModel>> getSections(
    String projectId,
    String canvasId,
  ) async {
    final snapshot = await projectsRef
        .doc(projectId)
        .collection('canvases')
        .doc(canvasId)
        .collection('sections')
        .orderBy('order')
        .get(forceServerFetch);
    return snapshot.docs.map((doc) => SectionModel.fromFirestore(doc)).toList();
  }

  Stream<List<BarModel>> streamBars(
    String projectId,
    String canvasId,
    String sectionId,
  ) {
    return projectsRef
        .doc(projectId)
        .collection('canvases')
        .doc(canvasId)
        .collection('sections')
        .doc(sectionId)
        .collection('bars')
        .orderBy('index')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => BarModel.fromFirestore(doc)).toList(),
        );
  }

  Future<List<BarModel>> getBars(
    String projectId,
    String canvasId,
    String sectionId,
  ) async {
    final snapshot = await projectsRef
        .doc(projectId)
        .collection('canvases')
        .doc(canvasId)
        .collection('sections')
        .doc(sectionId)
        .collection('bars')
        .orderBy('index')
        .get();
    return snapshot.docs.map((doc) => BarModel.fromFirestore(doc)).toList();
  }

  Future<List<CanvasModel>> getCanvases(String projectId) async {
    final snapshot = await projectsRef
        .doc(projectId)
        .collection('canvases')
        .orderBy('order')
        .get(forceServerFetch);
    return snapshot.docs.map((doc) => CanvasModel.fromFirestore(doc)).toList();
  }

  // join
  Future<ProjectModel> joinRoom(String roomCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final snapshot = await projectsRef
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

  // delete
  Future<void> deleteProject(String projectId) async {
    final doc = await projectsRef.doc(projectId).get();
    if (doc.exists) {
      final project = ProjectModel.fromFirestore(doc);
      final roomCode = project.roomCode;

      final rtdb = FirebaseDatabase.instance.ref();
      await rtdb.child('rooms/$roomCode').remove();
      await rtdb.child('playback_sessions/$projectId').remove();
    }
    await projectsRef.doc(projectId).delete();
  }

  // CHORD STUFF
  Future<void> updateBarChord({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required String barID,
    required int beatIndex,
    required String chord,
    required String userID,
  }) async {
    final barRef = projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc(sectionID)
        .collection('bars')
        .doc(barID);

    final doc = await barRef.get();
    final chords = List<String>.from(doc.data()?['chords'] ?? []);
    if (beatIndex < chords.length) chords[beatIndex] = chord; //cek index

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
    final barRef = projectsRef
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
    final barRef = projectsRef
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

    // nosql, buat kosong dulu
    final targetLength = mainChords.length > beatIndex
        ? mainChords.length
        : beatIndex + 1;
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
    final barRef = projectsRef
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

    final targetLength = mainChords.length > beatIndex
        ? mainChords.length
        : beatIndex + 1;
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

  // SECTION STUFF
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
    final sectionRef = projectsRef
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
        ...barToFirestore(
          BarModel(
            id: barRef.id,
            index: startBar + i,
            chords: List.from(empty),
          ),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> copySection({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required String name,
    required int order,
    required int barCount,
    required int startBar,
  }) async {
    final copiedBars = await getBars(projectID, canvasID, sectionID);

    final batch = _firestore.batch();
    final sectionRef = projectsRef
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

    for (int i = 0; i < copiedBars.length; i++) {
      final copiedBar = copiedBars[i];
      final barRef = sectionRef.collection('bars').doc();
      batch.set(barRef, {
        'index': startBar + i,
        'chords': List<String>.from(copiedBar.chords),
        'passingChord': List<String>.from(copiedBar.passingChord),
        'beatCount': copiedBar.beatCount,
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
    await projectsRef
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
    final sectionRef = projectsRef
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
      final section = reordered[i]; //set index
      final ref = projectsRef
          .doc(projectID)
          .collection('canvases')
          .doc(canvasID)
          .collection('sections')
          .doc(section.id);

      batch.update(ref, {
        'order': i,
        'startBar': runningStartBar,
      }); //update index

      runningStartBar += section.barCount;
    }
    await batch.commit();
  }

  // BAR STUFF
  Future<void> addBar({
    required String projectID,
    required String canvasID,
    required String sectionID,
    required int index,
    required int beatCount,
    required String timeSignature,
  }) async {
    final sectionRef = projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('sections')
        .doc(sectionID);

    // bar kosong
    final empty = List.filled(beatCount, '');
    final barRef = sectionRef.collection('bars').doc();

    final batch = _firestore.batch();
    batch.set(barRef, {
      ...barToFirestore(
        BarModel(
          id: barRef.id,
          index: index,
          chords: empty,
          beatCount: beatCount,
        ),
      ),
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
    final sectionRef = projectsRef
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
      final ref = projectsRef
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
    final barRef = projectsRef
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
      newChords = [
        ...currentChords,
        ...List.filled(newBeatCount - currentChords.length, ''),
      ];
      newPassing = [
        ...currentPassing,
        ...List.filled(newBeatCount - currentPassing.length, ''),
      ];
    } else {
      newChords = currentChords.sublist(0, newBeatCount);
      newPassing = currentPassing.sublist(
        0,
        newBeatCount.clamp(0, currentPassing.length),
      );
    }

    await barRef.update({
      'chords': newChords,
      'passingChord': newPassing,
      'beatCount': newBeatCount,
      'updatedBy': userID,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // CANVAS PARTITUR
  Future<CanvasModel> createCanvas({
    required String projectID,
    required String title,
    required double tempo,
    required String timeSignature,
    String type = 'manual',
    bool createEmptySections = true,
    Map<String, dynamic>? songTemplate,
  }) async {
    final projectRef = projectsRef.doc(projectID);
    final canvasRef = projectRef.collection('canvases').doc();

    final existingCanvases = await getCanvases(projectID);
    final order = existingCanvases.length;

    final canvas = CanvasModel(
      id: canvasRef.id,
      title: title,
      order: order,
      tempo: tempo,
      timeSignature: timeSignature,
      type: type,
    );

    final batch = _firestore.batch();

    batch.set(canvasRef, {
      ...canvasToFirestore(canvas),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (songTemplate != null) {
      addSongTemplateSections(batch, canvasRef, songTemplate, timeSignature);
    } else if (createEmptySections) {
      addTemplateSections(batch, canvasRef, timeSignature);
    }

    await batch.commit();
    return canvas;
  }

  Future<void> deleteCanvas({
    required String projectID,
    required String canvasID,
  }) async {
    final canvasRef = projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID);

    final sectionsSnap = await canvasRef.collection('sections').get();
    final batch = _firestore.batch();

    for (final sectionDoc in sectionsSnap.docs) {
      final barsSnap = await sectionDoc.reference.collection('bars').get();
      for (final barDoc in barsSnap.docs) {
        batch.delete(barDoc.reference);
      }
      batch.delete(sectionDoc.reference);
    }

    batch.delete(canvasRef);
    await batch.commit();

    await reorderCanvases(projectID);
  }

  // reorder list
  Future<void> reorderCanvases(String projectID) async {
    final canvases = await getCanvases(projectID);
    if (canvases.isEmpty) return;

    final batch = _firestore.batch();
    for (int i = 0; i < canvases.length; i++) {
      batch.update(
        projectsRef.doc(projectID).collection('canvases').doc(canvases[i].id),
        {'order': i},
      );
    }
    await batch.commit();
  }

  Future<void> updateCanvasTempo({
    required String projectID,
    required String canvasID,
    required int tempo,
  }) async {
    await projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .update({'tempo': tempo, 'updatedAt': FieldValue.serverTimestamp()});
  }
  
  // NOTES
  Stream<List<NoteModel>> streamNotes(String projectID, String canvasID) {
    return projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('notes')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addNote({
    required String projectID,
    required String canvasID,
    required String text,
    required double posX,
    required double posY,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not log in');

    await projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('notes')
        .add({
          'text': text,
          'posX': posX,
          'posY': posY,
          'createdBy': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> updateNote({
    required String projectID,
    required String canvasID,
    required String noteID,
    required Map<String, dynamic> data,
  }) async {
    await projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('notes')
        .doc(noteID)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteNote({
    required String projectID,
    required String canvasID,
    required String noteID,
  }) async {
    await projectsRef
        .doc(projectID)
        .collection('canvases')
        .doc(canvasID)
        .collection('notes')
        .doc(noteID)
        .delete();
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

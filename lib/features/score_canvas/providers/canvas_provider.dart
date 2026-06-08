import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/shared/models/note_model.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/models/bar_model.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';

// PARTRUR STREAM PROVIDERS

final canvasesStreamProvider = StreamProvider.family<List<CanvasModel>, String>(
  (ref, projectID) {
    final repository = ref.watch(projectRepositoryProvider);
    return repository.streamCanvases(projectID);
  },
);

final sectionsStreamProvider =
    StreamProvider.family<
      List<SectionModel>,
      ({String projectID, String canvasID})
    >((ref, params) {
      final repository = ref.watch(projectRepositoryProvider);
      return repository.streamSections(params.projectID, params.canvasID);
    });

final barsStreamProvider =
    StreamProvider.family<
      List<BarModel>,
      ({String projectID, String canvasID, String sectionID})
    >((ref, params) {
      final repository = ref.watch(projectRepositoryProvider);
      return repository.streamBars(
        params.projectID,
        params.canvasID,
        params.sectionID,
      );
    });

final notesStreamProvider =
    StreamProvider.family<
      List<NoteModel>,
      ({String projectID, String canvasID})
    >((ref, params) {
      final repository = ref.watch(projectRepositoryProvider);
      return repository.streamNotes(params.projectID, params.canvasID);
    });

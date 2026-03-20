import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/models/bar_model.dart';
import 'package:jam_sync/shared/models/project_model.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';

final projectStreamProvider = StreamProvider.family<ProjectModel, String>((ref, projectId) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.streamProject(projectId);
});

final canvasesStreamProvider = StreamProvider.family<List<CanvasModel>, String>((ref, projectId) {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.streamCanvases(projectId);
});

final sectionsStreamProvider =
    StreamProvider.family<List<SectionModel>, ({String projectId, String canvasId})>((ref, params) {
      final repository = ref.watch(projectRepositoryProvider);
      return repository.streamSections(params.projectId, params.canvasId);
    });

final barsStreamProvider =
    StreamProvider.family<List<BarModel>, ({String projectId, String canvasId, String sectionId})>((
      ref,
      params,
    ) {
      final repository = ref.watch(projectRepositoryProvider);
      return repository.streamBars(params.projectId, params.canvasId, params.sectionId);
    });

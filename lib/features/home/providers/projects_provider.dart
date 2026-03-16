import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/models/project_model.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';

final projectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getUserProjects();
});

import 'package:flutter_riverpod/legacy.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';

class CreateProjectState {
  final bool isLoading;
  final String? error;
  final String? createdProjectId;

  const CreateProjectState({
    this.isLoading = false,
    this.error,
    this.createdProjectId,
  });

  CreateProjectState copyWith({
    bool? isLoading,
    String? error,
    String? createdProjectId,
  }) {
    return CreateProjectState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdProjectId: createdProjectId,
    );
  }
}

class CreateProjectNotifier extends StateNotifier<CreateProjectState> {
  final ProjectRepository _repository;

  CreateProjectNotifier(this._repository)
      : super(const CreateProjectState());

  Future<bool> createProject({
    required String title,
    required String songTitle,
    required double tempo,
    required String timeSignature,
    required bool useTemplate,
    Map<String, dynamic>? songTemplate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final projectId = await _repository.createProject(
        title: title,
        songTitle: songTitle,
        tempo: tempo,
        timeSignature: timeSignature,
        useTemplate: useTemplate,
        songTemplate: songTemplate,
      );

      state = state.copyWith(
        isLoading: false,
        createdProjectId: projectId,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const CreateProjectState();
  }
}

final createProjectProvider =
    StateNotifierProvider<CreateProjectNotifier, CreateProjectState>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return CreateProjectNotifier(repository);
});

import 'package:flutter_riverpod/legacy.dart';
import 'package:jam_sync/shared/models/project_model.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';

class JoinRoomState {
  final bool isLoading;
  final String? error;
  final ProjectModel? joinedProject;

  const JoinRoomState({
    this.isLoading = false,
    this.error,
    this.joinedProject,
  });

  JoinRoomState copyWith({
    bool? isLoading,
    String? error,
    ProjectModel? joinedProject,
  }) {
    return JoinRoomState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      joinedProject: joinedProject ?? this.joinedProject,
    );
  }
}

class JoinRoomNotifier extends StateNotifier<JoinRoomState> {
  final ProjectRepository _repository;

  JoinRoomNotifier(this._repository) : super(const JoinRoomState());

  Future<bool> joinRoom(String roomCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final project = await _repository.joinRoom(roomCode);
      state = state.copyWith(isLoading: false, joinedProject: project);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const JoinRoomState();
  }
}

final joinRoomProvider =
    StateNotifierProvider<JoinRoomNotifier, JoinRoomState>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return JoinRoomNotifier(repository);
});

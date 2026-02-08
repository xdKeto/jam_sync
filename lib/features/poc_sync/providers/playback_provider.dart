import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jam_sync/features/poc_sync/services/sync_provider.dart';

final playbackServiceProvider = Provider((ref) => PlaybackService(ref));

class PlaybackService {
  final Ref ref;
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();

  PlaybackService(this.ref);

  Future<void> startPlayback(String roomId) async {
    final syncService = ref.read(pocSyncServiceProvider);

    // time now + buffer (5 detik)
    final serverStartTime = syncService.getEstimatedServerTime() + 5000;

    // trigger server playback status
    await rtdb.child('playback_sessions/$roomId').update({
      'serverStartTime': serverStartTime,
      'isPlaying': true,
    });
  }
}

class PlaybackState {
  final int currentBoxIndex;
  final bool isPlaying;
  final int currentPositionMs;

  const PlaybackState({
    this.currentBoxIndex = -1,
    this.isPlaying = false,
    this.currentPositionMs = 0,
  });

  PlaybackState copyWith({
    int? currentBoxIndex,
    bool? isPlaying,
    int? currentPositionMs,
  }) {
    return PlaybackState(
      currentBoxIndex: currentBoxIndex ?? this.currentBoxIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPositionMs: currentPositionMs ?? this.currentPositionMs,
    );
  }
}

final playbackControllerProvider =
    StateNotifierProvider<PlaybackController, PlaybackState>(
      (ref) => PlaybackController(ref),
    );

class PlaybackController extends StateNotifier<PlaybackState> {
  final Ref ref;
  Timer? playbackTimer;
  int serverStartTime = 0;

  static const int totalBoxes = 64;
  static const double beatDurationMs = 545.45; // 60000 / 110 BPM

  PlaybackController(this.ref) : super(const PlaybackState());

  void startAutonomousPlayback(int startTime) {
    serverStartTime = startTime;
    state = state.copyWith(isPlaying: true, currentBoxIndex: 0);

    final syncService = ref.read(pocSyncServiceProvider);

    playbackTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!state.isPlaying) {
        timer.cancel();
        return;
      }

      final currentPositionMs =
          syncService.getEstimatedServerTime() - serverStartTime;
      final currentBoxIndex = calculateBoxIndex(currentPositionMs);

      state = state.copyWith(
        currentBoxIndex: currentBoxIndex,
        currentPositionMs: currentPositionMs,
      );

      // s`top jika sudah selesai
      if (currentBoxIndex >= totalBoxes) {
        stopPlayback();
      }
    });
  }

  int calculateBoxIndex(int positionMs) {
    return (positionMs / beatDurationMs).floor();
  }

  void stopPlayback() {
    playbackTimer?.cancel();
    state = state.copyWith(isPlaying: false);
  }

  @override
  void dispose() {
    playbackTimer?.cancel();
    super.dispose();
  }
}

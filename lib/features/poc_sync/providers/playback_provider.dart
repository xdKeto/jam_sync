import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jam_sync/features/poc_sync/services/poc_mad_logger_service.dart';
import 'package:jam_sync/features/poc_sync/services/sync_provider.dart';

final playbackServiceProvider = Provider((ref) => PlaybackService(ref));
final pocMadLoggerProvider = Provider((ref) => PocMadLoggerService(ref));

class PlaybackService {
  final Ref ref;
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();

  PlaybackService(this.ref);

  Future<void> startPlayback(String roomId) async {
    final syncService = ref.read(pocSyncServiceProvider);

    // leader buat shared log session dulu sebelum countdown
    await createSharedLogSession(roomId);

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
  final double playbackProgress;
  final double smoothedPositionMs;
  final double alpha;

  const PlaybackState({
    this.currentBoxIndex = -1,
    this.isPlaying = false,
    this.currentPositionMs = 0,
    this.playbackProgress = 0.0,
    this.smoothedPositionMs = 0.0,
    this.alpha = 0.15, // faktor smooth, butuh tuning
  });

  PlaybackState copyWith({
    int? currentBoxIndex,
    bool? isPlaying,
    int? currentPositionMs,
    double? playbackProgress,
    double? smoothedPositionMs,
    double? alpha,
  }) {
    return PlaybackState(
      currentBoxIndex: currentBoxIndex ?? this.currentBoxIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPositionMs: currentPositionMs ?? this.currentPositionMs,
      playbackProgress: playbackProgress ?? this.playbackProgress,
      smoothedPositionMs: smoothedPositionMs ?? this.smoothedPositionMs,
      alpha: alpha ?? this.alpha,
    );
  }
}

final playbackControllerProvider =
    StateNotifierProvider<PlaybackController, PlaybackState>(
      (ref) => PlaybackController(ref),
    );

class PlaybackController extends StateNotifier<PlaybackState> {
  final Ref ref;
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
  Timer? playbackTimer;
  int serverStartTime = 0;
  String? currentRoomId;

  static const int totalBoxes = 64;
  static const double beatDurationMs = 545.45; // 60000 / 110 BPM

  PlaybackController(this.ref) : super(const PlaybackState());

  void startAutonomousPlayback(int startTime, {required String roomId}) async {
    serverStartTime = startTime;
    currentRoomId = roomId;
    state = state.copyWith(
      isPlaying: true,
      currentBoxIndex: 0,
      smoothedPositionMs: 0.0,
    );

    // start log
    final logger = ref.read(pocMadLoggerProvider);
    final sessionId = await getSharedLogSession(currentRoomId!);

    if (sessionId != null) {
      logger.startLog(sessionId, serverStartTime);
    }

    final syncService = ref.read(pocSyncServiceProvider);

    playbackTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!state.isPlaying) {
        timer.cancel();
        return;
      }

      // hitung untuk logging
      final currentPositionMs =
          syncService.getEstimatedServerTime() - serverStartTime;

      // interpolasi smoothing cursor
      final targetPositionMs = currentPositionMs.toDouble();
      final smoothedPositionMs =
          state.smoothedPositionMs +
          state.alpha * (targetPositionMs - state.smoothedPositionMs);

      // smoothed cursor
      final totalDurationMs = totalBoxes * beatDurationMs;
      final currentBoxIndex = (smoothedPositionMs / beatDurationMs).floor();
      final progress = (smoothedPositionMs / totalDurationMs).clamp(0.0, 1.0);

      state = state.copyWith(
        currentBoxIndex: currentBoxIndex,
        currentPositionMs: currentPositionMs,
        playbackProgress: progress,
        smoothedPositionMs: smoothedPositionMs,
      );

      // stop
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
    state = state.copyWith(isPlaying: false, smoothedPositionMs: 0.0);

    // stop log
    ref.read(pocMadLoggerProvider).stopLog();

    if (currentRoomId != null) {
      rtdb.child('playback_sessions/$currentRoomId').update({
        'isPlaying': false,
        'serverStartTime': 0,
      });
    }
  }

  // void updatePosition(double smoothedPositionMs, double alpha) {
  //   final syncService = ref.read(pocSyncServiceProvider);
  //   final targetPositionMs =
  //       (syncService.getEstimatedServerTime() - serverStartTime).toDouble();

  //   smoothedPositionMs =
  //       smoothedPositionMs + alpha * (targetPositionMs - smoothedPositionMs);

  //   final currentBoxIndex = (smoothedPositionMs / 545.45).floor();
  // }

  @override
  void dispose() {
    playbackTimer?.cancel();
    super.dispose();
  }
}

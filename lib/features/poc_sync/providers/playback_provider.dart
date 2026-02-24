import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jam_sync/features/poc_sync/providers/room_provider.dart';
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
  final double correctionOffsetMs;

  const PlaybackState({
    this.currentBoxIndex = -1,
    this.isPlaying = false,
    this.currentPositionMs = 0,
    this.playbackProgress = 0.0,
    this.smoothedPositionMs = 0.0,
    this.alpha = 0.15, // faktor smooth, butuh tuning
    this.correctionOffsetMs = 0.0,
  });

  PlaybackState copyWith({
    int? currentBoxIndex,
    bool? isPlaying,
    int? currentPositionMs,
    double? playbackProgress,
    double? smoothedPositionMs,
    double? alpha,
    double? correctionOffsetMs,
  }) {
    return PlaybackState(
      currentBoxIndex: currentBoxIndex ?? this.currentBoxIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPositionMs: currentPositionMs ?? this.currentPositionMs,
      playbackProgress: playbackProgress ?? this.playbackProgress,
      smoothedPositionMs: smoothedPositionMs ?? this.smoothedPositionMs,
      alpha: alpha ?? this.alpha,
      correctionOffsetMs: correctionOffsetMs ?? this.correctionOffsetMs,
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
  bool firstResync = false;

  static const double decay = 0.98;

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
      final decayedOffset = state.correctionOffsetMs * decay;
      final targetPositionMs = currentPositionMs.toDouble() + decayedOffset;
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
        correctionOffsetMs: decayedOffset,
      );

      // stop
      if (currentBoxIndex >= totalBoxes) {
        stopPlayback();
      }
    });

    // ===== resinkronisasi =====
    final resyncService = ref.read(pocResyncServiceProvider);
    final roomState = ref.read(roomProvider);

    // leader broadcast, follower listen
    if (roomState.isLeader) {
      resyncService.startBroadcast(currentRoomId!, serverStartTime);
    } else {
      firstResync = false;
      resyncService.listenToLeaderPosition(
        currentRoomId!,
        onLeaderPositionUpdate,
      );
    }
    // ===== resinkronisasi =====
  }

  int calculateBoxIndex(int positionMs) {
    return (positionMs / beatDurationMs).floor();
  }

  void stopPlayback() {
    // stop resync
    final resyncService = ref.read(pocResyncServiceProvider);
    final roomState = ref.read(roomProvider);
    if (roomState.isLeader) {
      resyncService.stopBroadcast(currentRoomId!);
    }
    resyncService.stopListening();

    // stop playback
    playbackTimer?.cancel();
    playbackTimer = null;

    state = state.copyWith(
      isPlaying: false,
      smoothedPositionMs: 0.0,
      correctionOffsetMs: 0.0,
    );

    // stop log
    ref.read(pocMadLoggerProvider).stopLog();

    if (currentRoomId != null && roomState.isLeader) {
      rtdb.child('playback_sessions/$currentRoomId').update({
        'isPlaying': false,
        'serverStartTime': 0,
      });
    }
  }

  void onLeaderPositionUpdate(int position, int broadcastTime) {
    // skip initial snapshot dari RTDB (data lama)
    if (!firstResync) {
      firstResync = true;
      return;
    }

    final syncService = ref.read(pocSyncServiceProvider);
    final now = syncService.getEstimatedServerTime();

    // nyesuain ke leader latency
    final latency = now - broadcastTime;
    final leaderPosition = position + latency;

    // lokal
    final localPosition = now - serverStartTime;
    final delta = leaderPosition - localPosition;

    // smoothing posisi
    final smoothFactor = 0.3; // hrs tuning lagi
    if (latency < 0 || latency > 1000) return;
    if (delta.abs() < 5) return;
    final clampDelta = delta.clamp(-200, 200); //koreksi
    final smoothing = clampDelta * smoothFactor;

    // update state
    state = state.copyWith(
      correctionOffsetMs: state.correctionOffsetMs + smoothing,
    );
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
    playbackTimer = null;
    super.dispose();
  }
}

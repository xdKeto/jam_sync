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

    // NTP quick re-calibration sebelum mulai (jika aktif)
    if (PocSyncService.useNtpCalibration) {
      await syncService.calibrateQuick();
    }

    // leader buat shared log session dulu sebelum countdown
    await createSharedLogSession(roomId);

    // time now + buffer (8 detik)
    final serverStartTime = syncService.getEstimatedServerTime() + 8000;

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
  List<int> recentDelta = [];

  // ===== TOGGLE: ganti true/false untuk testing =====
  // true = resync aktif, false = tanpa resync
  static const bool enableResync = false;
  // true = one-time startup correction aktif
  static const bool enableStartupCorrection = true;
  // ================================================

  static const double decay = 0.98;

  static const int totalBoxes = 64;
  static const double beatDurationMs = 545.45; // 60000 / 110 BPM

  PlaybackController(this.ref) : super(const PlaybackState());

  void startAutonomousPlayback(int startTime, {required String roomId}) async {
    serverStartTime = startTime;
    currentRoomId = roomId;
    recentDelta = [];
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
      final error = (targetPositionMs - state.smoothedPositionMs).abs();
      final flexAlpa = error > 50 ? 0.3 : state.alpha;
      final smoothedPositionMs =
          state.smoothedPositionMs +
          flexAlpa * (targetPositionMs - state.smoothedPositionMs);

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
    if (enableResync) {
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
    }
    // ===== resinkronisasi =====

    // ===== one-time startup correction =====
    if (enableStartupCorrection) {
      final resyncService = ref.read(pocResyncServiceProvider);
      final roomState = ref.read(roomProvider);

      if (roomState.isLeader) {
        resyncService.broadcastOnce(currentRoomId!, serverStartTime);
      } else {
        resyncService.listenOnce(currentRoomId!, onStartupCorrectionReceived);
      }
    }
    // ===== one-time startup correction =====
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

    recentDelta = [];
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

    // cek latency
    final latency = now - broadcastTime;
    // final leaderPosition = position + latency;
    if (latency < 0 || latency > 350) return;

    // lokal
    final localPosition = broadcastTime - serverStartTime;
    final delta = position - localPosition; //selisih leader

    // sampling delta
    recentDelta.add(delta);
    if (recentDelta.length > 3) recentDelta.removeAt(0);
    if (recentDelta.length < 2) return;

    final sorted = List<int>.from(recentDelta)..sort();
    final median = sorted[sorted.length ~/ 2];

    // hitung smoothing posisi
    final smoothFactor = 0.3; // hrs tuning lagi
    if (median.abs() < 5) return;
    final clampDelta = median.clamp(-200, 200); // guard tuk delta
    final smoothing = clampDelta * smoothFactor;

    // update state
    state = state.copyWith(
      correctionOffsetMs: (state.correctionOffsetMs + smoothing).clamp(
        -100,
        100,
      ),
    );
  }

  void onStartupCorrectionReceived(int leaderPosition, int broadcastTime) {
    final syncService = ref.read(pocSyncServiceProvider);
    final now = syncService.getEstimatedServerTime();

    // cek latency wajar
    final latency = now - broadcastTime;
    if (latency < 0 || latency > 200) {
      print("Startup correction skipped: bad latency ${latency}ms");
      return;
    }

    // posisi lokal pada saat leader broadcast
    final localPosition = broadcastTime - serverStartTime;
    final delta = leaderPosition - localPosition;

    // skip jika sudah cukup akurat
    if (delta.abs() < 5) {
      print("Startup correction skipped: delta ${delta}ms (already good)");
      return;
    }

    // clamp delta agar tidak over-correct
    final clampedDelta = delta.clamp(-30, 30);
    syncService.serverTimeOffset += clampedDelta;
    print(
      "Startup correction applied: rawDelta=${delta}ms, clamped=${clampedDelta}ms, new offset=${syncService.serverTimeOffset}",
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

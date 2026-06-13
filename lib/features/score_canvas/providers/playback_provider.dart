import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jam_sync/shared/models/bar_model.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/features/score_canvas/services/sync_service.dart';
import 'package:jam_sync/features/score_canvas/services/main_logger_service.dart';
import 'package:uuid/uuid.dart';

enum PlaybackPhase { idle, syncing, countdown, playing, ended }

class PlaybackState {
  final PlaybackPhase phase;
  final int countdownBeat;
  final double beatProgress;
  final double smoothedPositionMs;
  // final int currentBarIndex;
  final double playbackProgress;
  final int totalBars;
  final int serverStartTime;
  final double tempo;
  final String timeSignature;
  final bool isLeader;
  final String roomID;
  final String projectID;
  final String canvasID;
  // final double correctionOffsetMs;
  final Map<int, int> barIndexMap;

  const PlaybackState({
    this.phase = PlaybackPhase.idle,
    this.countdownBeat = 4,
    this.beatProgress = 0,
    this.smoothedPositionMs = 0,
    // this.currentBarIndex = 0,
    this.playbackProgress = 0,
    this.totalBars = 0,
    this.serverStartTime = 0,
    this.tempo = 120,
    this.timeSignature = '4/4',
    this.isLeader = false,
    this.roomID = '',
    this.projectID = '',
    this.canvasID = '',
    // this.correctionOffsetMs = 0,
    this.barIndexMap = const {},
  });

  PlaybackState copyWith({
    PlaybackPhase? phase,
    int? countdownBeat,
    double? beatProgress,
    double? smoothedPositionMs,
    // int? currentBarIndex,
    double? playbackProgress,
    int? totalBars,
    int? serverStartTime,
    double? tempo,
    String? timeSignature,
    bool? isLeader,
    String? roomID,
    String? projectID,
    String? canvasID,
    // double? correctionOffsetMs,
    Map<int, int>? barIndexMap,
  }) {
    return PlaybackState(
      phase: phase ?? this.phase,
      countdownBeat: countdownBeat ?? this.countdownBeat,
      beatProgress: beatProgress ?? this.beatProgress,
      smoothedPositionMs: smoothedPositionMs ?? this.smoothedPositionMs,
      // currentBarIndex: currentBarIndex ?? this.currentBarIndex,
      playbackProgress: playbackProgress ?? this.playbackProgress,
      totalBars: totalBars ?? this.totalBars,
      serverStartTime: serverStartTime ?? this.serverStartTime,
      tempo: tempo ?? this.tempo,
      timeSignature: timeSignature ?? this.timeSignature,
      isLeader: isLeader ?? this.isLeader,
      roomID: roomID ?? this.roomID,
      projectID: projectID ?? this.projectID,
      canvasID: canvasID ?? this.canvasID,
      // correctionOffsetMs: correctionOffsetMs ?? this.correctionOffsetMs,
      barIndexMap: barIndexMap ?? this.barIndexMap,
    );
  }

  double get beatDuration => 60000 / tempo;
}

class PlaybackProviderParams {
  final String projectID;
  final String canvasID;
  final String roomID;
  final bool isLeader;
  final double tempo;
  final String timeSignature;
  final int countdownBeats;
  final List<SectionModel> sections;
  final Future<List<BarModel>> Function(String sectionID)? getBarsForSection;
  final bool enableHalfwayResync;

  const PlaybackProviderParams({
    required this.projectID,
    required this.canvasID,
    required this.roomID,
    required this.isLeader,
    required this.tempo,
    required this.timeSignature,
    required this.countdownBeats,
    required this.sections,
    this.getBarsForSection,
    this.enableHalfwayResync = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaybackProviderParams &&
        other.projectID == projectID &&
        other.canvasID == canvasID &&
        other.roomID == roomID &&
        other.tempo == tempo &&
        other.enableHalfwayResync == enableHalfwayResync;
  }

  @override
  int get hashCode =>
      Object.hash(projectID, canvasID, roomID, tempo, enableHalfwayResync);
}

class PlaybackController extends StateNotifier<PlaybackState> {
  final PlaybackProviderParams params;
  final SyncService syncService;
  final ResyncService resyncService;
  late final MainLoggerService logger;

  Timer? countdownTimer;
  Timer? playbackTimer;
  Timer? syncingTimer;
  StreamSubscription? rtdbListener;
  bool isInitialized = false;
  bool halfwayResyncFired = false;

  final Map<int, int> barIndexMap = {};

  String? logSessionId;
  int serverStartTime = 0;
  int capturedOffset = 0;
  int countdownBeats = 4;
  late double tempo;
  double beatDurationMs = 500;
  int countdownDurationMs = 0;
  String? userID;
  DatabaseReference? viewerRef;
  StreamSubscription? viewerCountListener;

  PlaybackController({
    required this.params,
    required this.syncService,
    required this.resyncService,
  }) : super(
         PlaybackState(
           tempo: params.tempo,
           timeSignature: params.timeSignature,
           isLeader: params.isLeader,
           roomID: params.roomID,
           projectID: params.projectID,
           canvasID: params.canvasID,
           totalBars: computeTotalBars(params.sections),
         ),
       ) {
    tempo = params.tempo;
    beatDurationMs = 60000 / params.tempo;
    countdownBeats = params.countdownBeats;

    logger = MainLoggerService(syncService: syncService);

    setupRTDBListener();
  }

  // ====== MANAJEMEN ROOM ======

  Future<void> initPlaybackSession() async {
    await joinPlaybackSession();
    watchViewerCount();
  }

  // join
  Future<void> joinPlaybackSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    userID = user.uid;
    final viewerPath = 'playback_sessions/${params.roomID}/viewers/$userID';
    viewerRef = FirebaseDatabase.instance.ref().child(viewerPath);

    // set timestamep
    await viewerRef!.set({
      'joinedAt': ServerValue.timestamp,
      'isLeader': params.isLeader,
      'displayName': user.displayName ?? 'Unknown',
    });

    await viewerRef!.onDisconnect().remove();
  }

  //
  Future<void> leavePlaybackSession() async {
    if (userID == null || userID!.isEmpty) return;

    final viewerPath = 'playback_sessions/${params.roomID}/viewers/$userID';
    await FirebaseDatabase.instance.ref().child(viewerPath).remove();
  }

  //
  void watchViewerCount() {
    viewerCountListener = FirebaseDatabase.instance
        .ref()
        .child('playback_sessions/${params.roomID}')
        .onValue
        .listen((event) {
          if (!event.snapshot.exists) return;

          final sessionData = event.snapshot.value as Map<dynamic, dynamic>;

          // skip
          final serverStartTime = sessionData['serverStartTime'] as int? ?? 0;
          if (serverStartTime == 0) return;

          final viewers = sessionData['viewers'] as Map<dynamic, dynamic>?;
          if (viewers == null || viewers.isEmpty) {
            resetPlaybackSession(); // kalo gaada orang, reset
          }
        });
  }

  void setupRTDBListener() {
    if (isInitialized || params.isLeader) return;
    isInitialized = true;

    rtdbListener = FirebaseDatabase.instance
        .ref()
        .child('playback_sessions/${params.roomID}')
        .onValue
        .listen(onRTDBValue);
  }

  void onRTDBValue(DatabaseEvent event) {
    if (!event.snapshot.exists) return;
    final data = Map<String, dynamic>.from(event.snapshot.value as Map);
    final startTime = data['serverStartTime'] as int?;

    // end
    if (startTime == null || startTime == 0) {
      syncingTimer?.cancel();
      syncingTimer = null;
      countdownTimer?.cancel();
      playbackTimer?.cancel();
      isInitialized = false;
      if (!params.isLeader) {
        logger.stopLog();
      }
      state = state.copyWith(phase: PlaybackPhase.ended);
      return;
    }

    // new sesi
    if (startTime > 0 &&
        state.phase != PlaybackPhase.syncing &&
        state.phase != PlaybackPhase.countdown &&
        state.phase != PlaybackPhase.playing) {
      serverStartTime = startTime;
      countdownBeats = data['countdownBeats'] as int? ?? params.countdownBeats;
      tempo = params.tempo;
      beatDurationMs = 60000 / tempo;
      countdownDurationMs = (countdownBeats * beatDurationMs).round();
      state = state.copyWith(phase: PlaybackPhase.syncing);
      startSyncingPolling();
    }
  }

  // reset state
  void resetToIdle({PlaybackPhase phase = PlaybackPhase.idle}) {
    syncingTimer?.cancel();
    countdownTimer?.cancel();
    playbackTimer?.cancel();
    halfwayResyncFired = false;
    isInitialized = false;
    if (!params.isLeader) {
      rtdbListener?.cancel();
      rtdbListener = null;
      rtdbListener = FirebaseDatabase.instance
          .ref()
          .child('playback_sessions/${params.roomID}')
          .onValue
          .listen(onRTDBValue);
    }
    state = PlaybackState(
      phase: phase,
      tempo: params.tempo,
      timeSignature: params.timeSignature,
      isLeader: params.isLeader,
      roomID: params.roomID,
      projectID: params.projectID,
      canvasID: params.canvasID,
      totalBars: state.totalBars,
    );
  }

  // reset sesi
  Future<void> resetPlaybackSession() async {
    final roomRef = FirebaseDatabase.instance.ref().child(
      'playback_sessions/${params.roomID}',
    );

    await roomRef.update({
      'isPlaying': false,
      'serverStartTime': 0,
      'playbackIntent': null,
      'sessionId': null,
      'startupCorrection': null,
      'halfwayCorrection': null,
    });

    // reset member
    final participantsRef = roomRef.child('participants');
    final snapshot = await participantsRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final updates = <String, dynamic>{};
      for (final key in data.keys) {
        updates['$key/isReady'] = false;
      }
      await participantsRef.update(updates);
    }

    logger.stopLog();

    // state
    resetToIdle(phase: PlaybackPhase.ended);
  }

  // ====== SYNCING LOGIC ======

  Future<void> preparePlayback() async {
    if (!params.isLeader) return;

    state = state.copyWith(phase: PlaybackPhase.syncing);
    await syncService.smartQuickCalibrate(); // last check

    // get partitur
    await buildBarIndexMapAsync(params.sections);
    // if (params.getBarsForSection != null) {}

    state = state.copyWith(barIndexMap: Map.from(barIndexMap));

    countdownDurationMs = (countdownBeats * beatDurationMs).round();
    serverStartTime =
        syncService.getEstimatedServerTime() + countdownDurationMs + 5000;

    final sessionId = const Uuid().v4();

    // logging
    final logSession = await createMainLogSession(params.roomID);
    logSessionId = logSession;

    logger.updateOffset(
      syncService.serverTimeOffset,
      syncService.serverTimeOffset,
    );

    await FirebaseDatabase.instance
        .ref()
        .child('playback_sessions/${params.roomID}')
        .update({
          'serverStartTime': serverStartTime,
          'countdownBeats': countdownBeats,
          'isPlaying': true,
          'sessionId': sessionId,
        });

    startSyncingPolling();
  }

  void startSyncingPolling() {
    syncingTimer?.cancel();
    syncingTimer = null;
    syncingTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      final now = syncService.getEstimatedServerTime();
      final beatStartTime = serverStartTime - countdownDurationMs;

      if (now >= beatStartTime) {
        timer.cancel();
        syncingTimer = null;
        final elapsed = now - beatStartTime;
        if (elapsed > beatDurationMs && state.phase == PlaybackPhase.syncing) {
          forceMinCountdown(); //telat
        } else {
          startCountdown();
        }
      }
    });
  }

  void forceMinCountdown() {
    serverStartTime =
        syncService.getEstimatedServerTime() + beatDurationMs.round();

    state = state.copyWith(
      phase: PlaybackPhase.countdown,
      countdownBeat: 1,
      beatProgress: 0,
    );

    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      //telat
      final now = syncService.getEstimatedServerTime();
      final elapsed = now - (serverStartTime - beatDurationMs.round());
      if (elapsed >= beatDurationMs) {
        timer.cancel();
        startPlayback();
      } else {
        final progress = (elapsed / beatDurationMs).clamp(0.0, 1.0);
        state = state.copyWith(beatProgress: progress);
      }
    });
  }

  void startCountdown() {
    final countdownEndTime = serverStartTime - countdownDurationMs;

    state = state.copyWith(
      phase: PlaybackPhase.countdown,
      countdownBeat: countdownBeats,
      beatProgress: 0,
    );

    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      //cek terus
      final now = syncService.getEstimatedServerTime();
      final totalElapsed = now - countdownEndTime;

      if (totalElapsed >= countdownDurationMs) {
        timer.cancel();
        startPlayback();
      } else {
        final elapsedBeats = totalElapsed / beatDurationMs;
        final currentBeat = (countdownBeats - elapsedBeats).ceil().clamp(
          1,
          countdownBeats,
        );
        final rawProgress = (totalElapsed % beatDurationMs) / beatDurationMs;
        final beatProgress = rawProgress.clamp(0.0, 1.0);

        // update ke ui
        state = state.copyWith(
          countdownBeat: currentBeat,
          beatProgress: beatProgress,
        );
      }
    });
  }

  Future<void> startMemberLogging() async {
    final sessionId = await getMainLogSession(params.roomID);

    if (sessionId != null) {
      logSessionId = sessionId;
      logger.updateOffset(
        syncService.serverTimeOffset,
        syncService.serverTimeOffset,
      );
      logger.startLog(sessionId, serverStartTime, tempo);
    }
  }

  // ====== CORE LOGIC ======

  void startPlayback() {
    countdownTimer?.cancel();
    halfwayResyncFired = false;
    capturedOffset = syncService.serverTimeOffset;

    state = state.copyWith(
      phase: PlaybackPhase.playing,
      smoothedPositionMs: 0,
      // currentBarIndex: 0,
      playbackProgress: 0,
      // correctionOffsetMs: 0,
      barIndexMap: Map.from(barIndexMap),
    );

    // logging
    if (params.isLeader && logSessionId != null) {
      logger.updateOffset(
        syncService.serverTimeOffset,
        syncService.serverTimeOffset,
      );
      logger.startLog(logSessionId!, serverStartTime, tempo);
    }

    if (!params.isLeader) {
      startMemberLogging();
    }

    playbackTimer = Timer.periodic(
      Duration(milliseconds: 16),
      (_) => autonomousPlayback(),
    );

    // if (params.isLeader) {
    //   resyncService.broadcastPosition(params.roomID, serverStartTime, delay: 2000);
    // } else {
    //   resyncService.listenPosition(params.roomID, false, handleCorrection, timeout: Duration(seconds: 5));
    //   if (params.enableHalfwayResync) {
    //     resyncService.listenPosition(params.roomID, true, (position, broadcastTime) {
    //       handleCorrection(position, broadcastTime);
    //     });
    //   }
    // }
  }

  void autonomousPlayback() {
    if (state.phase != PlaybackPhase.playing) return;

    final now = DateTime.now().millisecondsSinceEpoch + capturedOffset;
    final rawPosition = (now - serverStartTime).toDouble();

    // final decayedOffset = state.correctionOffsetMs * 0.98;
    // final targetPosition = rawPosition + decayedOffset;

    // smoothing
    final error = rawPosition - state.smoothedPositionMs;
    final alpha = error.abs() > 50 ? 0.3 : 0.15;
    final smoothed = state.smoothedPositionMs + alpha * error;

    // cek
    if (isPlaybackEnded()) {
      playbackTimer?.cancel();
      if (params.isLeader) {
        resetPlaybackSession();
      }
      state = state.copyWith(phase: PlaybackPhase.ended);
      return;
    }

    // if (params.isLeader && params.enableHalfwayResync && !halfwayResyncFired) {
    //   final halfwayBar = state.totalBars ~/ 2;
    //   if (barIndex >= halfwayBar) {
    //     halfwayResyncFired = true;
    //     resyncService.broadcastHalfway(
    //       params.roomID,
    //       smoothed.round(),
    //       syncService.getEstimatedServerTime(),
    //     );
    //   }
    // }

    // update state
    state = state.copyWith(
      smoothedPositionMs: smoothed,
      // currentBarIndex: barIndex,
      playbackProgress: totalDurationMs > 0
          ? (smoothed / totalDurationMs).clamp(0.0, 1.0)
          : 0,
      // correctionOffsetMs: decayedOffset,
    );
  }

  // check playback
  bool isPlaybackEnded() {
    if (barIndexMap.isEmpty || state.totalBars <= 0) return false;

    final totalDuration = totalDurationMs; //get
    if (totalDuration <= 0) return false;

    if (state.smoothedPositionMs < 1000) return false;

    return state.smoothedPositionMs > totalDuration;
  }

  void stop() {
    syncingTimer?.cancel();
    countdownTimer?.cancel();
    playbackTimer?.cancel();
    resetPlaybackSession();
  }

  // void handleCorrection(int leaderPosition, int broadcastTime) {
  //   final latency = syncService.getEstimatedServerTime() - broadcastTime;
  //   if (latency < 0 || latency > 200) return;

  //   final diff = leaderPosition - state.smoothedPositionMs;
  //   if (diff.abs() < 5) return;

  //   final clampedDiff = diff.clamp(-30.0, 30.0);
  //   state = state.copyWith(correctionOffsetMs: clampedDiff);
  // }

  // ====== HELPER FUNCTIONS ======

  static int computeTotalBars(List<SectionModel> sections) {
    int total = 0;
    for (final section in sections) {
      total += section.barCount;
    }
    return total;
  }

  // hasil fetch data, jadiin bar index map
  Future<void> buildBarIndexMapAsync(List<SectionModel> sections) async {
    barIndexMap.clear();
    int cumulative = 0;
    int barIdx = 0;

    for (final section in sections) {
      List<BarModel> bars = [];
      try {
        bars = await params.getBarsForSection!(section.id);
      } catch (_) {
        bars = [];
      }
      // if (params.getBarsForSection != null) {}

      for (int i = 0; i < section.barCount; i++) {
        barIndexMap[barIdx] = cumulative;
        final beatCount = (i < bars.length && bars[i].beatCount != null)
            ? bars[i].beatCount!
            : beatsPerBar(params.timeSignature);
        cumulative += beatCount;
        barIdx++;
      }
    }
  }

  // helper, bar ini berapa ketukan ya?
  int getBarBeatCount(int barIndex) {
    if (barIndexMap.isEmpty) return 4;
    final sortedKeys = barIndexMap.keys.toList()..sort();
    if (barIndex >= sortedKeys.length) return 4;

    final currentCumulative =
        barIndexMap[sortedKeys[barIndex]]!; // start mulai bar ini
    final nextCumulative =
        (barIndex + 1 < sortedKeys.length) // start mulai bar next
        ? barIndexMap[sortedKeys[barIndex + 1]]!
        : currentCumulative + 4;
    return nextCumulative - currentCumulative; // selisih = ketukan bar ini
  }

  double get totalDurationMs {
    if (barIndexMap.isEmpty || state.totalBars <= 0) {
      int totalBeats = 0;
      for (final section in params.sections) {
        totalBeats += section.barCount * beatsPerBar(params.timeSignature);
      }
      if (totalBeats == 0) totalBeats = 16;
      return totalBeats * beatDurationMs;
    }
    final sortedKeys = barIndexMap.keys.toList()..sort();
    if (sortedKeys.isEmpty) return 0;

    final lastBar = sortedKeys.last;
    final lastCumulative = barIndexMap[lastBar]!;
    final lastBarBeats = getBarBeatCount(lastBar);

    return (lastCumulative + lastBarBeats) *
        beatDurationMs; // total beat * durasi beat = lama lagu (ms)
  }

  // int positionToBarIndex(double positionMs) {
  //   if (positionMs < 0 || barIndexMap.isEmpty) return 0;

  //   final beats = positionMs / beatDurationMs; // beat keberapa
  //   final found = findBarSectionHelper(beats, barIndexMap);

  //   if (found == -1) return 0;
  //   return found.clamp(0, state.totalBars > 0 ? state.totalBars - 1 : 0);
  // }

  // // cari bar index berdasarkan beat keberapa
  // int findBarSectionHelper(double beats, Map<int, int> beatMap) {
  //   if (beatMap.isEmpty) return -1;

  //   List<int> keys = beatMap.keys.toList()..sort();
  //   int left = 0;
  //   int right = keys.length - 1;

  //   if (beats < 0) return -1;

  //   // binary searchhh
  //   int result = -1;
  //   while (left <= right) {
  //     int mid = left + (right - left) ~/ 2;
  //     int midKey = keys[mid];
  //     int midValue = beatMap[midKey]!;

  //     if (midValue <= beats) {
  //       result = midKey;
  //       left = mid + 1;
  //     } else {
  //       right = mid - 1;
  //     }
  //   }

  //   return result;
  // }

  @override
  void dispose() {
    syncingTimer?.cancel();
    countdownTimer?.cancel();
    playbackTimer?.cancel();
    rtdbListener?.cancel();
    viewerCountListener?.cancel();
    viewerRef?.remove();
    leavePlaybackSession();
    logger.dispose();
    super.dispose();
  }
}

final playbackProvider =
    StateNotifierProvider.family<
      PlaybackController,
      PlaybackState,
      PlaybackProviderParams
    >((ref, params) {
      final syncService = ref.read(syncServiceProvider);
      final resyncService = ref.read(resyncProvider);
      return PlaybackController(
        params: params,
        syncService: syncService,
        resyncService: resyncService,
      );
    });

PlaybackController playbackController(
  WidgetRef ref,
  PlaybackProviderParams params,
) {
  return ref.read(playbackProvider(params).notifier);
}

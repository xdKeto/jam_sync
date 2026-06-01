import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/features/score_canvas/providers/playback_provider.dart';
import 'package:jam_sync/features/score_canvas/providers/room_provider.dart';
import 'package:jam_sync/features/score_canvas/services/sync_service.dart';
import 'package:jam_sync/features/score_canvas/widgets/playback/countdown_overlay.dart';
import 'package:jam_sync/features/score_canvas/widgets/playback/dev_settings_sheet.dart';
import 'package:jam_sync/features/score_canvas/widgets/playback/playback_canvas.dart';
import 'package:jam_sync/features/score_canvas/widgets/playback/playback_controls.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';

class PlaybackScreen extends ConsumerStatefulWidget {
  final String projectID;
  final String canvasID;
  final String roomID;
  final String roomCode;
  final bool isLeader;
  final PlaybackSettings settings;
  final List<SectionModel> sections;
  final double tempo;
  final String timeSignature;
  final String title;

  const PlaybackScreen({
    super.key,
    required this.projectID,
    required this.canvasID,
    required this.roomID,
    required this.roomCode,
    required this.isLeader,
    required this.settings,
    required this.sections,
    required this.tempo,
    required this.timeSignature,
    required this.title,
  });

  @override
  ConsumerState<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends ConsumerState<PlaybackScreen> {
  late PlaybackProviderParams params;
  bool controlsVisible = true;
  Timer? hideControlsTimer;
  bool started = false;
  bool sessionStale = false;

  /// Track section data version to invalidate cached sectionStartBarIndex
  // int _sectionsVersion = 0;

  /// Cached section start bar index to avoid recalculating
  // Map<String, int>? _cachedSectionStartBarIndex;

  /// Build a map of section ID -> global starting bar index
  /// Uses ACTUAL bar counts from Firestore, not section.barCount metadata
  // Future<Map<String, int>> _buildSectionStartBarIndexAsync(List<SectionModel> sections) async {
  //   final repo = ref.read(projectRepositoryProvider);
  //   int cumulativeBars = 0;
  //   final result = <String, int>{};

  //   for (final section in sections) {
  //     result[section.id] = cumulativeBars;
  //     // Fetch actual bars to get correct count
  //     final bars = await repo.getBars(widget.projectID, widget.canvasID, section.id);
  //     cumulativeBars += bars.length;
  //   }

  //   // _cachedSectionStartBarIndex = result;
  //   return result;
  // }

  Map<String, int> buildSectionStartBarIndex(List<SectionModel> sections) {
    int cumulativeBars = 0;
    final result = <String, int>{};
    for (final section in sections) {
      result[section.id] = cumulativeBars;
      cumulativeBars += section.barCount;
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    startInitPlayback();
  }

  Future<void> startInitPlayback() async {
    final repository = ref.read(projectRepositoryProvider);
    final canvases = await repository.getCanvases(widget.projectID);
    final currentCanvas = canvases
        .where((c) => c.id == widget.canvasID)
        .firstOrNull;
    final currentTempo = currentCanvas?.tempo ?? widget.tempo;
    final currentTimeSignature =
        currentCanvas?.timeSignature ?? widget.timeSignature;

    if (!mounted) return;

    params = PlaybackProviderParams(
      projectID: widget.projectID,
      canvasID: widget.canvasID,
      roomID: widget.roomID,
      isLeader: widget.isLeader,
      tempo: currentTempo,
      timeSignature: currentTimeSignature,
      countdownBeats: widget.settings.countdownBeats,
      sections: widget.sections,
      enableHalfwayResync: widget.settings.enableHalfwayResync,
      getBarsForSection: (sectionID) async {
        final repo = ref.read(projectRepositoryProvider);
        return repo.getBars(widget.projectID, widget.canvasID, sectionID);
      },
    );

    initPlayback();
    setupPlaybackListener();

    setState(() {});
  }

  void setupPlaybackListener() {
    ref.listen<PlaybackState>(playbackProvider(params), (previous, next) async {
      if (previous?.phase != PlaybackPhase.ended &&
          next.phase == PlaybackPhase.ended) {
        await resetIntentState();
      }
    });
  }

  void initPlayback() async {
    if (started) return;
    started = true;

    if (!widget.isLeader) {
      final roomState = ref.read(roomProvider);
      final isStale = checkSessionStale(roomState.serverStartTime);

      if (isStale) {
        setState(() => sessionStale = true);
        return;
      }
    }

    final currentState = ref.read(playbackProvider(params));
    if (currentState.phase != PlaybackPhase.idle) {
      playbackController(ref, params).resetToIdle();
    }

    if (widget.isLeader) {
      final controller = playbackController(ref, params);

      await controller.initPlaybackSession();
      controller.preparePlayback();
    }

    scheduleHideControls();
  }

  // cek sesi expired
  bool checkSessionStale(int serverStartTime) {
    if (serverStartTime <= 0) {
      return false;
    }

    final syncService = ref.read(syncServiceProvider);
    final now = syncService.getEstimatedServerTime();
    final elapsedMs = now - serverStartTime;

    if (elapsedMs < 0) {
      return false;
    }

    final barDurationMs =
        (60000 / widget.tempo) * beatsPerBar(widget.timeSignature);
    int totalBars = 0;
    for (final section in widget.sections) {
      totalBars += section.barCount;
    }
    if (totalBars == 0) totalBars = 4;

    final countdownDurationMs = 4 * barDurationMs;
    final playbackDurationMs = totalBars * barDurationMs;
    final totalSessionMs = countdownDurationMs + playbackDurationMs + 2000;

    // harusnya udah selesai, tapi masih jalan (elapsed) = expired
    return elapsedMs > totalSessionMs;
  }

  // clear intent
  Future<void> resetIntentState() async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('playback_sessions/${widget.roomID}/playbackIntent')
          .remove();
    } catch (e) {
      debugPrint('PlaybackScreen: failed to clear playbackIntent: $e');
    }
  }

  void scheduleHideControls() {
    hideControlsTimer?.cancel();
    hideControlsTimer = Timer(Duration(seconds: 3), () {
      if (mounted) setState(() => controlsVisible = false);
    });
  }

  void onTapToShowControls() {
    if (!controlsVisible) {
      setState(() => controlsVisible = true);
      scheduleHideControls();
    } else {
      hideControlsTimer?.cancel();
      hideControlsTimer = Timer(Duration(seconds: 3), () {
        if (mounted) setState(() => controlsVisible = false);
      });
    }
  }

  @override
  void dispose() {
    hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!started) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // data partitur
    final sectionsAsync = ref.watch(
      sectionsStreamProvider((
        projectID: widget.projectID,
        canvasID: widget.canvasID,
      )),
    );

    final currentSections = sectionsAsync.value ?? widget.sections;

    // Track section changes to trigger barIndexMap rebuild
    // final sectionCount = currentSections.length;
    // if (sectionCount != _sectionsVersion) {
    //   _sectionsVersion = sectionCount;
    //   // Rebuild barIndexMap and sectionStartBarIndex with fresh section data
    //   WidgetsBinding.instance.addPostFrameCallback((_) async {
    //     if (!mounted) return;
    //     if (params.getBarsForSection != null) {
    //       await playbackController(ref, params).rebuildBarIndexMap(currentSections);
    //     }
    //     // Also rebuild sectionStartBarIndex with actual bar counts
    //     await _buildSectionStartBarIndexAsync(currentSections);
    //     if (mounted) {
    //       setState(() {});
    //     }
    //   });
    // }

    final state = ref.watch(playbackProvider(params));
    final controller = playbackController(ref, params);

    if (sessionStale) {
      return SafeArea(
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange[700],
                ),
                const SizedBox(height: 16),
                Text(
                  'Session Expired',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'This playback session has ended. Returning to canvas...',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Canvas'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          onTap: onTapToShowControls,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              PlaybackCanvas(
                projectID: widget.projectID,
                canvasID: widget.canvasID,
                scrollOffset: 0,
                currentIndex: state.currentBarIndex,
                smoothedPositionMs: state.smoothedPositionMs,
                isPlaying: state.phase == PlaybackPhase.playing,
                isEditable: state.phase != PlaybackPhase.playing,
                barIndexMap: state.barIndexMap,
                sectionStartBarIndex: buildSectionStartBarIndex(
                  currentSections,
                ),
                playbackParams: params,
                title: widget.title,
              ),
              CountdownOverlay(params: params),
              PlaybackControls(
                isVisible: controlsVisible,
                roomCode: widget.roomCode,
                phase: state.phase,
                isLeader: widget.isLeader,
                onStop: () => controller.stop(),
                onClose: () async {
                  await resetIntentState();
                  controller.stop();
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

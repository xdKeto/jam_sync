import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/playback_intent_provider.dart';
import 'package:jam_sync/features/score_canvas/providers/room_provider.dart';
import 'package:jam_sync/features/score_canvas/screens/playback_screen.dart';
import 'package:jam_sync/features/score_canvas/services/sync_service.dart';
import 'package:jam_sync/features/score_canvas/widgets/playback/dev_settings_sheet.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';

// auto navigate member
class PlaybackAutoNavigator extends ConsumerStatefulWidget {
  final Widget child;
  final String projectID;
  final String canvasID;
  final String? canvasTitle;
  final List<SectionModel> sections;
  final double tempo;
  final String timeSignature;

  const PlaybackAutoNavigator({
    super.key,
    required this.child,
    required this.projectID,
    required this.canvasID,
    this.canvasTitle,
    required this.sections,
    required this.tempo,
    required this.timeSignature,
  });

  @override
  ConsumerState<PlaybackAutoNavigator> createState() =>
      _PlaybackAutoNavigatorState();
}

class _PlaybackAutoNavigatorState extends ConsumerState<PlaybackAutoNavigator> {
  bool hasNavigated = false;

  Future<void> navigateToPlayback(String roomCode, int countdownBeats) async {
    final repository = ref.read(projectRepositoryProvider);
    final canvases = await repository.getCanvases(widget.projectID);

    final intentParams = PlaybackIntentParams(
      roomID: ref.read(roomProvider).roomID!,
      projectID: widget.projectID,
      defaultCanvasID: widget.canvasID,
      roomCode: roomCode,
      userID: FirebaseAuth.instance.currentUser?.uid ?? '',
      isLeader: false,
      userName: FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown',
      tempo: widget.tempo,
      timeSignature: widget.timeSignature,
      countdownBeats: countdownBeats,
      sections: widget.sections,
    );
    final intentState = ref.read(playbackIntentProvider(intentParams));
    final targetCanvasId = intentState.selectedCanvasId ?? widget.canvasID;
    final targetCanvas = canvases.where((c) => c.id == targetCanvasId).firstOrNull;
    final currentTempo = targetCanvas?.tempo ?? widget.tempo;
    final currentTimeSignature = targetCanvas?.timeSignature ?? widget.timeSignature;
    final canvasTitle = targetCanvas?.title ?? widget.canvasTitle ?? '';

    final targetSections = await repository.getSections(widget.projectID, targetCanvasId);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PlaybackScreen(
          projectID: widget.projectID,
          canvasID: targetCanvasId,
          roomID: widget.projectID,
          roomCode: roomCode,
          isLeader: false,
          settings: PlaybackSettings(countdownBeats: countdownBeats, enableHalfwayResync: true),
          sections: targetSections,
          tempo: currentTempo,
          timeSignature: currentTimeSignature,
          title: canvasTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.read(syncServiceProvider); // watch

    final roomState = ref.watch(roomProvider);
    final userID = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (roomState.roomID == null || roomState.roomID!.isEmpty) {
      return widget.child;
    }

    final isLeader = roomState.leaderID == userID;

    final intentParams = PlaybackIntentParams(
      roomID: roomState.roomID!,
      projectID: roomState.roomID!,
      defaultCanvasID: widget.canvasID,
      roomCode: roomState.roomCode ?? '',
      userID: userID,
      isLeader: isLeader,
      userName: FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown',
      tempo: widget.tempo,
      timeSignature: widget.timeSignature,
      countdownBeats: 4,
      sections: widget.sections,
    );

    final intentState = ref.watch(playbackIntentProvider(intentParams)); //watch

    if (roomState.serverStartTime == 0) {
      hasNavigated = false;
    }

    // cek rtdb
    if (!isLeader &&
        roomState.serverStartTime > 0 &&
        intentState.isMyReady &&
        !hasNavigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentRoom = ref.read(roomProvider);
        final currentIntent = ref.read(playbackIntentProvider(intentParams));
        if (currentRoom.serverStartTime > 0 &&
            currentIntent.isMyReady &&
            !hasNavigated) {
          hasNavigated = true;
          navigateToPlayback(currentRoom.roomCode ?? '', currentRoom.countdownBeats);
        }
      });
    }

    return widget.child;
  }
}
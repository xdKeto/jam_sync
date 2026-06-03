import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/features/score_canvas/providers/participants_provider.dart';
import 'package:jam_sync/features/score_canvas/providers/playback_intent_provider.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/features/score_canvas/providers/room_provider.dart';
import 'package:jam_sync/features/score_canvas/screens/playback_screen.dart';
import 'package:jam_sync/features/score_canvas/widgets/playback/dev_settings_sheet.dart';
import 'package:jam_sync/features/score_canvas/widgets/playback/playback_auto_navigator.dart';
import 'package:jam_sync/features/score_canvas/widgets/participant_tile.dart';
import 'package:jam_sync/shared/models/participant_info_model.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/background_gradient.dart';
import 'package:jam_sync/shared/widgets/the_button.dart';

class TeamDashboard extends ConsumerStatefulWidget {
  final String projectID;
  final List<SectionModel> sections;
  final String canvasID;
  final String canvasTitle;

  const TeamDashboard({
    super.key,
    required this.projectID,
    required this.sections,
    required this.canvasID,
    required this.canvasTitle,
  });

  @override
  ConsumerState<TeamDashboard> createState() => _TeamDashboardState();
}

class _TeamDashboardState extends ConsumerState<TeamDashboard> {
  late String _userID;
  late String _userName;

  @override
  void initState() {
    super.initState();
    _userID = FirebaseAuth.instance.currentUser?.uid ?? '';
    _userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final participantsAsync = ref.watch(
      participantsStreamProvider(widget.projectID),
    );

    // streams
    final canvasesAsync = ref.watch(canvasesStreamProvider(widget.projectID));
    final canvases = canvasesAsync.value ?? [];
    final currentCanvas = canvases
        .where((c) => c.id == widget.canvasID)
        .firstOrNull;
    final currentTempo = currentCanvas?.tempo ?? 120.0;
    final currentTimeSignature = currentCanvas?.timeSignature ?? '4/4';

    final isLeader = roomState.leaderID == _userID;

    final intentParams = PlaybackIntentParams(
      // intent
      roomID: widget.projectID,
      projectID: widget.projectID,
      defaultCanvasID: widget.canvasID,
      roomCode: roomState.roomCode ?? '',
      userID: _userID,
      isLeader: isLeader,
      userName: _userName,
      tempo: currentTempo,
      timeSignature: currentTimeSignature,
      countdownBeats: 4,
      sections: widget.sections,
    );
    final intentState = ref.watch(playbackIntentProvider(intentParams));
    final intentController = ref.read(
      playbackIntentProvider(intentParams).notifier,
    );

    // select partitur
    if (isLeader && intentController.selectedCanvasId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          intentController.initSelectedCanvas(
            widget.canvasID,
            currentCanvas?.title ?? 'Partitur',
          );
        }
      });
    }

    // auto navigator
    return PlaybackAutoNavigator(
      projectID: widget.projectID,
      canvasID: widget.canvasID,
      sections: widget.sections,
      tempo: currentTempo,
      timeSignature: currentTimeSignature,
      canvasTitle: currentCanvas?.title ?? 'Partitur',
      child: BackgroundGradient(
        usePadding: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppStyles.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Team Dashboard",
                  style: AppStyles.h3(context).copyWith(color: AppStyles.white),
                ),
                Text(
                  "Room: ${roomState.roomCode ?? '-'}",
                  style: AppStyles.bodySmall(
                    context,
                  ).copyWith(color: AppStyles.lightTeal),
                ),
              ],
            ),
            toolbarHeight: 80,
            backgroundColor: AppStyles.darkNavy,
            actions: [
              // IMPORTANT TODO: setting pengujian aja, reminder hapus
              if (isLeader)
                Tooltip(
                  message: 'Reset Playback (Debug)',
                  child: IconButton(
                    icon: const Icon(Icons.bug_report, color: Colors.orange),
                    onPressed: () => showDebugResetDialog(context),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: buildBottomBar(
              context,
              isLeader: isLeader,
              isPlaybackLive: roomState.serverStartTime > 0,
              intentState: intentState,
              intentController: intentController,
              canvases: canvases,
            ),
          ),
          body: participantsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            data: (participantList) {
              if (participantList.isEmpty) {
                return Center(
                  child: Text(
                    'No participants yet',
                    style: AppStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppStyles.white),
                  ),
                );
              }

              final sorted = List<ParticipantInfo>.from(participantList)
                ..sort((a, b) {
                  if (a.isLeader) return -1;
                  if (b.isLeader) return 1;
                  if (a.isOnline && !b.isOnline) return -1;
                  if (!a.isOnline && b.isOnline) return 1;
                  return a.displayName.compareTo(b.displayName);
                });

              return Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      decoration: AppStyles.whiteBox(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sorted.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return ParticipantTile(participant: sorted[index]);
                        },
                      ),
                    ),
                  ),
                  if (isLeader && intentState.state == IntentState.waiting)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        (intentState.totalOnline - 1) > 0
                            ? 'Waiting for ${intentState.notReadyNames.length} of ${intentState.totalOnline - 1} members...'
                            : intentState.isMyReady
                            ? 'All ready! Starting...'
                            : 'Waiting...',
                        style: AppStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppStyles.grey400),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  8.height,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildBottomBar(
    BuildContext context, {
    required bool isLeader,
    required bool isPlaybackLive,
    required PlaybackIntentState intentState,
    required PlaybackIntentController intentController,
    required List<CanvasModel> canvases,
  }) {
    if (isLeader) {
      return buildLeaderControls(
        context,
        isPlaybackLive,
        intentState,
        intentController,
        canvases,
      );
    }
    return buildMemberControls(
      context,
      isPlaybackLive,
      intentState,
      intentController,
      canvases,
    );
  }

  Widget buildLeaderControls(
    BuildContext context,
    bool isPlaybackLive,
    PlaybackIntentState intentState,
    PlaybackIntentController intentController,
    List<CanvasModel> canvases,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (intentState.state == IntentState.idle) ...[
              canvases.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppStyles.grey800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.music_note,
                            color: AppStyles.lightTeal,
                            size: 20,
                          ),
                          8.width,
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: intentController.selectedCanvasId.isEmpty
                                    ? (canvases.isNotEmpty
                                          ? canvases.first.id
                                          : null)
                                    : (canvases.any(
                                            (c) =>
                                                c.id ==
                                                intentController
                                                    .selectedCanvasId,
                                          )
                                          ? intentController.selectedCanvasId
                                          : (canvases.isNotEmpty
                                                ? canvases.first.id
                                                : null)),
                                isExpanded: true,
                                dropdownColor: AppStyles.grey700,
                                style: AppStyles.bodyMedium(
                                  context,
                                ).copyWith(color: AppStyles.white),
                                items: canvases.map((canvas) {
                                  return DropdownMenuItem<String>(
                                    value: canvas.id,
                                    child: Text(
                                      canvas.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppStyles.bodyMedium(
                                        context,
                                      ).copyWith(color: AppStyles.white),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    final canvas = canvases.firstWhere(
                                      (c) => c.id == value,
                                    );
                                    intentController.setSelectedCanvas(
                                      value,
                                      canvas.title,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              12.height,
            ],
            intentState.state == IntentState.idle
                ? GestureDetector(
                    onTap: () => intentController.sendIntent(),
                    child: TheButton(
                      text: "Start Jamming",
                      color: AppStyles.darkNavy,
                      textColor: AppStyles.white,
                    ),
                  )
                : intentState.state == IntentState.waiting
                ? Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => intentController.cancelIntent(),
                          child: TheButton(
                            text: "Cancel",
                            color: AppStyles.grey800,
                            textColor: AppStyles.white,
                          ),
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: GestureDetector(
                          onTap: () => intentController.toggleReady(),
                          child: TheButton(
                            text: intentState.isMyReady ? "Ready!" : "Ready Up",
                            color: intentState.isMyReady
                                ? AppStyles.success
                                : AppStyles.darkNavy,
                            textColor: AppStyles.white,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => intentController.cancelIntent(),
                          child: TheButton(
                            text: "Cancel",
                            color: AppStyles.grey800,
                            textColor: AppStyles.white,
                          ),
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              onStartPlayback(context, intentController),
                          child: TheButton(
                            text: "Start",
                            color: AppStyles.darkNavy,
                            textColor: AppStyles.white,
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget buildMemberControls(
    BuildContext context,
    bool isPlaybackLive,
    PlaybackIntentState intentState,
    PlaybackIntentController intentController,
    List<CanvasModel> canvases,
  ) {
    // banner info playback onging
    if (isPlaybackLive) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TheButton(
                text: "Playback in progress",
                color: AppStyles.grey600,
                textColor: AppStyles.white,
              ),
            ],
          ),
        ),
      );
    }

    final hasIntent = intentState.isIntentSent;
    final isMyReady = intentState.isMyReady;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIntent && intentState.selectedCanvasTitle != null) ...[
              selectedPartitur(intentState),
              12.height,
            ],
            GestureDetector(
              onTap: hasIntent ? () => intentController.toggleReady() : null,
              child: TheButton(
                text: isMyReady ? "Ready!" : "Ready Up",
                color: isMyReady ? AppStyles.success : AppStyles.darkNavy,
                textColor: AppStyles.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget selectedPartitur(PlaybackIntentState intentState) {
    final title = intentState.selectedCanvasTitle;
    if (title == null || title.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppStyles.grey800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppStyles.lightTeal, size: 20),
          8.width,
          Expanded(
            child: Text(
              'Leader memilih: $title',
              style: AppStyles.bodySmall(
                context,
              ).copyWith(color: AppStyles.lightTeal),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onStartPlayback(
    BuildContext context,
    PlaybackIntentController intentController,
  ) async {
    final roomState = ref.read(roomProvider);
    final selectedCanvasId = intentController.selectedCanvasId;
    final selectedCanvasTitle = intentController.selectedCanvasTitle;

    // fetch fetch
    final repository = ref.read(projectRepositoryProvider);
    final canvases = await repository.getCanvases(widget.projectID);
    final currentCanvas = canvases
        .where((c) => c.id == selectedCanvasId)
        .firstOrNull;
    final currentTempo = currentCanvas?.tempo ?? 120.0;
    final currentTimeSignature = currentCanvas?.timeSignature ?? '4/4';
    final selectedSections = await repository.getSections(
      widget.projectID,
      selectedCanvasId,
    );

    if (!context.mounted) return;

    // IMPORTANT TODO: setting pengujian aja, reminder hapus
    // final settings = await DevSettingsSheet.show(context, defaultCountdownBeats: 4);

    // if (settings == null) return;
    // if (!context.mounted) return;
    
    const settings = PlaybackSettings(
      enableHalfwayResync: false,
      countdownBeats: 4,
    );

    intentController.resetIntent();

    //leader only, member auto
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PlaybackScreen(
          projectID: widget.projectID,
          canvasID: selectedCanvasId,
          roomID: widget.projectID,
          roomCode: roomState.roomCode ?? '',
          isLeader: true,
          settings: settings,
          sections: selectedSections,
          tempo: currentTempo,
          timeSignature: currentTimeSignature,
          title: selectedCanvasTitle,
        ),
      ),
    );
  }

  // IMPORTANT TODO: setting pengujian aja, reminder hapus
  Future<void> showDebugResetDialog(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('Debug Stick'),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(roomProvider.notifier).forceResetAndRebuildSections();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('State Reset.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:jam_sync/features/score_canvas/widgets/team_dashboard.dart';
import 'package:jam_sync/features/score_canvas/widgets/playback/playback_auto_navigator.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/features/score_canvas/widgets/canvas_widget.dart';
import 'package:jam_sync/features/score_canvas/widgets/canvas_option_sheet.dart';
import 'package:jam_sync/features/score_canvas/widgets/edit_option_sheet.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/dialog_helpers.dart';
import 'package:jam_sync/shared/widgets/home_nav.dart';
import 'package:jam_sync/shared/widgets/tempo_picker.dart';
import 'package:jam_sync/features/score_canvas/providers/room_provider.dart';

class ScoreCanvasScreen extends ConsumerStatefulWidget {
  final String projectID;
  final String roomCode;

  const ScoreCanvasScreen({
    super.key,
    required this.projectID,
    required this.roomCode,
  });

  @override
  ConsumerState<ScoreCanvasScreen> createState() => _ScoreCanvasScreenState();
}

class _ScoreCanvasScreenState extends ConsumerState<ScoreCanvasScreen> {
  static const double kTempoBreakpoint = 400.0;
  String? selectedCanvasId;

  Future<bool> confirmLeaveRoom(BuildContext context) async {
    return showConfirmDialog(
      context,
      title: 'Leave Room?',
      content: 'You will be disconnected from the session.',
      confirmText: 'Leave',
    );
  }

  void showCanvasSelection(BuildContext context, List<CanvasModel> canvases) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppStyles.white,
      builder: (context) {
        return CanvasOptionSheet(
          projectID: widget.projectID,
          canvases: canvases,
          selectedCanvasId: selectedCanvasId,
          onCanvasSelected: (canvas) {
            setState(() {
              selectedCanvasId = canvas.id;
            });
          },
          onCanvasDeleted: () {
            final remainingCanvases =
                ref.read(canvasesStreamProvider(widget.projectID)).value ?? [];
            if (remainingCanvases.isNotEmpty && selectedCanvasId != null) {
              final stillExists = remainingCanvases.any(
                (c) => c.id == selectedCanvasId,
              );
              if (!stillExists) {
                setState(() {
                  selectedCanvasId = remainingCanvases.first.id;
                });
              }
            } else {
              setState(() {
                selectedCanvasId = remainingCanvases.isNotEmpty
                    ? remainingCanvases.first.id
                    : null;
              });
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvasesAsync = ref.watch(canvasesStreamProvider(widget.projectID));
    final canvases = canvasesAsync.value ?? [];
    final roomState = ref.watch(roomProvider);

    final currentCanvas = canvases.isNotEmpty
        ? canvases.firstWhere(
            (c) => c.id == selectedCanvasId,
            orElse: () => canvases.first,
          )
        : null;
    final titleToDisplay = currentCanvas?.title ?? "Score Canvas";

    final sectionsAsync = currentCanvas != null
        ? ref.watch(
            sectionsStreamProvider((
              projectID: widget.projectID,
              canvasID: currentCanvas.id,
            )),
          )
        : null;

    final isPlaybackLive = roomState.serverStartTime > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await confirmLeaveRoom(context);
        if (!shouldLeave || !context.mounted) return;
        ref.read(roomProvider.notifier).leaveRoom();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: PlaybackAutoNavigator(
        projectID: widget.projectID,
        canvasID: currentCanvas?.id ?? '',
        canvasTitle: currentCanvas?.title ?? 'Partitur',
        sections: sectionsAsync?.value ?? [],
        tempo: currentCanvas?.tempo ?? 120,
        timeSignature: currentCanvas?.timeSignature ?? '4/4',
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: AppStyles.darkNavy,
              elevation: 8,
              scrolledUnderElevation: 8,
              leading: IconButton(
                icon: const Icon(Icons.home, color: AppStyles.white),
                onPressed: () async {
                  final shouldLeave = await confirmLeaveRoom(context);
                  if (!shouldLeave || !context.mounted) return;
                  ref.read(roomProvider.notifier).leaveRoom();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeNav()),
                    (route) => false,
                  );
                },
              ),
              title: GestureDetector(
                onTap: () {
                  showCanvasSelection(context, canvases);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left, color: AppStyles.white),
                    8.width,
                    Flexible(
                      child: Text(
                        titleToDisplay,
                        style: AppStyles.h3(
                          context,
                        ).copyWith(color: AppStyles.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    8.width,
                    const Icon(Icons.chevron_right, color: AppStyles.white),
                  ],
                ),
              ),
              centerTitle: true,
              actionsPadding: const EdgeInsets.symmetric(horizontal: 8),
              actions: [
                Material(
                  color: AppStyles.mediumBlue,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamDashboard(
                            projectID: widget.projectID,
                            sections: sectionsAsync?.value ?? [],
                            canvasID: currentCanvas?.id ?? '',
                            canvasTitle: currentCanvas?.title ?? 'Partitur',
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.group, color: AppStyles.white),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppStyles.white,
            body: SafeArea(
              child: Column(
                children: [
                  if (isPlaybackLive) const LivePlaybackBanner(),
                  Expanded(
                    child: canvasesAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Text(
                          'Error: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      data: (canvases) {
                        if (currentCanvas == null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.music_square,
                                  size: 64,
                                  color: AppStyles.grey400,
                                ),
                                16.height,
                                Text(
                                  'Empty Canvas, create new section!',
                                  style: AppStyles.h3(
                                    context,
                                  ).copyWith(color: AppStyles.grey400),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CanvasWidget(
                                projectID: widget.projectID,
                                canvasID: currentCanvas.id,
                                timeSignature: currentCanvas.timeSignature,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              color: AppStyles.darkNavy,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Container(
                      decoration: AppStyles.whiteBox(),
                      child: IconButton(
                        icon: const Icon(
                          Iconsax.edit_2,
                          color: AppStyles.darkNavy,
                        ),
                        onPressed: () {
                          if (currentCanvas == null) return;
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: AppStyles.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (_) => EditOptionSheet(
                              projectID: widget.projectID,
                              canvasID: currentCanvas.id,
                              timeSignature: currentCanvas.timeSignature,
                            ),
                          );
                        },
                      ),
                    ),
                    Spacer(),
                    if (MediaQuery.of(context).size.width >= kTempoBreakpoint)
                      TempoControl(
                        initialTempo: currentCanvas?.tempo.round() ?? 120,
                        projectID: widget.projectID,
                        canvasID: currentCanvas?.id ?? '',
                      )
                    else
                      TempoIconButton(
                        tempo: currentCanvas?.tempo.round() ?? 120,
                        onTap: () {
                          if (currentCanvas == null) return;
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) => TempoSheet(
                              initialTempo: currentCanvas.tempo.round(),
                              projectID: widget.projectID,
                              canvasID: currentCanvas.id,
                            ),
                          );
                        },
                      ),
                    Spacer(),
                    Container(
                      decoration: AppStyles.whiteBox(),
                      child: IconButton(
                        icon: const Icon(
                          Iconsax.document_download,
                          color: AppStyles.darkNavy,
                        ),
                        onPressed: () {
                          if (currentCanvas == null) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppStyles.warning,
                              content: Text(
                                'Export to PDF feature coming soon!',
                                style: AppStyles.bodyMedium(
                                  context,
                                ).copyWith(color: AppStyles.white),
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LivePlaybackBanner extends StatelessWidget {
  const LivePlaybackBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: AppStyles.success.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppStyles.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppStyles.white.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'LIVE PLAYBACK IN PROGRESS',
            style: AppStyles.bodyMedium(context).copyWith(
              color: AppStyles.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

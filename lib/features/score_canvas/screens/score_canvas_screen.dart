import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:jam_sync/features/score_canvas/widgets/team_dashboard.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/features/score_canvas/widgets/canvas_widget.dart';
import 'package:jam_sync/features/score_canvas/widgets/canvas_option_sheet.dart';
import 'package:jam_sync/shared/widgets/home_nav.dart';
import 'package:jam_sync/features/score_canvas/providers/room_provider.dart';

class ScoreCanvasScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String roomCode;

  const ScoreCanvasScreen({super.key, required this.projectId, required this.roomCode});

  @override
  ConsumerState<ScoreCanvasScreen> createState() => _ScoreCanvasScreenState();
}

class _ScoreCanvasScreenState extends ConsumerState<ScoreCanvasScreen> {
  CanvasModel? selectedCanvas;

  Future<bool> confirmLeaveRoom(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room?'),
        content: const Text('You will be disconnected from the session.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
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
          canvases: canvases,
          selectedCanvas: selectedCanvas,
          onCanvasSelected: (canvas) {
            setState(() {
              selectedCanvas = canvas;
            });
          },
        );
      },
    );
  }

  void showTeamInfo(BuildContext context) {}

  @override
  Widget build(BuildContext context) {
    final canvasesAsync = ref.watch(canvasesStreamProvider(widget.projectId));
    final canvases = canvasesAsync.value ?? [];

    final currentCanvas = selectedCanvas ?? (canvases.isNotEmpty ? canvases.first : null);
    final titleToDisplay = currentCanvas?.title ?? "Score Canvas";

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await confirmLeaveRoom(context);
        if (!shouldLeave || !context.mounted) return;
        ref.read(roomProvider.notifier).leaveRoom();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
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
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    titleToDisplay,
                    style: AppStyles.h3(context).copyWith(color: AppStyles.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
                      builder: (context) => TeamDashboard(projectId: widget.projectId),
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
          child: canvasesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),
            data: (canvases) {
              if (currentCanvas == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.music_square, size: 64, color: AppStyles.grey400),
                      const SizedBox(height: 16),
                      Text(
                        'Empty Canvas, create new section!',
                        style: AppStyles.h3(context).copyWith(color: AppStyles.grey400),
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
                      projectId: widget.projectId,
                      canvasId: currentCanvas.id,
                      timeSignature: currentCanvas.timeSignature,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: AppStyles.darkNavy,
          child: Row(children: [
        
        ],),
        ),
      ),
    );
  }
}

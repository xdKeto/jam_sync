import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/features/score_canvas/providers/playback_provider.dart';
import 'package:jam_sync/features/score_canvas/widgets/draggable_note_widget.dart';
import 'package:jam_sync/features/score_canvas/widgets/playback/playback_section_widget.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class PlaybackCanvas extends ConsumerStatefulWidget {
  final String projectID;
  final String canvasID;
  final double scrollOffset;
  final int currentIndex;
  final double smoothedPositionMs;
  final bool isPlaying;
  final bool isEditable;
  final Map<int, int> barIndexMap;
  final Map<String, int> sectionStartBarIndex;
  final PlaybackProviderParams playbackParams;
  final String? title;

  const PlaybackCanvas({
    super.key,
    required this.projectID,
    required this.canvasID,
    required this.scrollOffset,
    required this.currentIndex,
    required this.smoothedPositionMs,
    required this.isPlaying,
    this.isEditable = true,
    this.barIndexMap = const {},
    this.sectionStartBarIndex = const {},
    required this.playbackParams,
    this.title,
  });

  @override
  ConsumerState<PlaybackCanvas> createState() => _PlaybackCanvasState();
}

class _PlaybackCanvasState extends ConsumerState<PlaybackCanvas> {
  final TransformationController transformController = TransformationController();
  final GlobalKey canvasKey = GlobalKey();
  bool isClamping = false;
  Size viewportSize = Size.zero;
  double cachedContentHeight = 300;
  bool _initialZoomApplied = false;

  static const double canvasWidth = 1000;
  static const double barWidth = canvasWidth / 4; // 250
  static const double canvasPadding = 16.0;
  static const double totalCanvasWidth = canvasWidth + canvasPadding * 2;

  @override
  void initState() {
    super.initState();
    transformController.addListener(onTransformChanged);
  }

  void ensureInitialZoomApplied() {
    if (_initialZoomApplied) return;
    if (viewportSize == Size.zero) return;

    final minScale = (viewportSize.width / totalCanvasWidth).clamp(0.1, 1.0);
    if (transformController.value.getMaxScaleOnAxis() == minScale) {
      _initialZoomApplied = true;
      return;
    }

    isClamping = true;
    transformController.value = Matrix4.identity()..scale(minScale, minScale);
    isClamping = false;
    _initialZoomApplied = true;
  }

  @override
  void dispose() {
    transformController.removeListener(onTransformChanged);
    transformController.dispose();
    super.dispose();
  }

  void onTransformChanged() {
    if (isClamping || viewportSize == Size.zero) return;

    final matrix = transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    double tx = matrix[12];
    double ty = matrix[13];

    final scaledW = totalCanvasWidth * scale;
    final scaledH = cachedContentHeight * scale;

    double clampedTx = tx;
    double clampedTy = ty;

    if (scaledW <= viewportSize.width) {
      clampedTx = 0;
    } else {
      clampedTx = tx.clamp(-(scaledW - viewportSize.width), 0.0);
    }

    if (scaledH <= viewportSize.height) {
      clampedTy = 0;
    } else {
      clampedTy = ty.clamp(-(scaledH - viewportSize.height), 0.0);
    }

    if (clampedTx != tx || clampedTy != ty) {
      isClamping = true;
      final newMatrix = matrix.clone();
      newMatrix[12] = clampedTx;
      newMatrix[13] = clampedTy;
      transformController.value = newMatrix;
      isClamping = false;
    }
  }

  void updateCachedHeight() {
    final renderBox = canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      if (cachedContentHeight != renderBox.size.height) {
        setState(() {
          cachedContentHeight = renderBox.size.height;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackProvider(widget.playbackParams));
    final tempo = playbackState.tempo;
    final beatDurationMs = 60000 / tempo;

    final sectionAsync = ref.watch(
      sectionsStreamProvider((projectID: widget.projectID, canvasID: widget.canvasID)),
    );

    final notesAsync = ref.watch(notesStreamProvider((
      projectID: widget.projectID,
      canvasID: widget.canvasID,
    )));

    final timeSignature = playbackState.timeSignature;

    return sectionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text("Error: $e", style: const TextStyle(color: AppStyles.error)),
      ),
      data: (sections) {
        if (sections.isEmpty) {
          return Center(
            child: Text(
              'Empty Canvas, go back and create a section!',
              style: AppStyles.h3(context).copyWith(color: AppStyles.grey400),
              textAlign: TextAlign.center,
            ),
          );
        }

        final notes = notesAsync.value ?? [];

        // hasil hitungan autonomous
        final beatPosition = widget.smoothedPositionMs / beatDurationMs;
        final currentBeatIndex = beatPosition.floor();

        return LayoutBuilder(
          builder: (context, constraints) {
            viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              updateCachedHeight();
              ensureInitialZoomApplied();
            });

            final minScale = (viewportSize.width / totalCanvasWidth).clamp(0.1, 1.0);

            return InteractiveViewer(
              transformationController: transformController,
              minScale: minScale,
              maxScale: 2.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              constrained: false,
              child: Padding(
                key: canvasKey,
                padding: const EdgeInsets.all(canvasPadding),
                child: SizedBox(
                  width: canvasWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(widget.title!, style: AppStyles.h2(context)),
                          ],
                        ),
                        12.height,
                      ],
                      Stack(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...sections.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final section = entry.value;
                                  return PlaybackSectionWidget(
                                    projectID: widget.projectID,
                                    canvasID: widget.canvasID,
                                    timeSignature: timeSignature,
                                    section: section,
                                    isFirst: idx == 0,
                                    barWidth: barWidth,
                                    canvasWidth: canvasWidth,
                                    isEditable: widget.isEditable,
                                    currentBeatIndex: widget.isPlaying ? currentBeatIndex : -1,
                                    barIndexMap: widget.barIndexMap,
                                    sectionStartBarIndex: widget.sectionStartBarIndex[section.id] ?? 0,
                                    beatPosition: widget.isPlaying ? beatPosition : -1,
                                  );
                                }),
                            ],
                          ),
                          ...notes.map((note) => DraggableNoteWidget(
                                note: note,
                                projectID: widget.projectID,
                                canvasID: widget.canvasID,
                                canvasWidth: canvasWidth,
                                isEditable: widget.isEditable,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
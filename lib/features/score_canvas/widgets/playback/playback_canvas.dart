import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/features/score_canvas/widgets/playback/playback_cursor.dart';
import 'package:jam_sync/shared/utils/playback_layout.dart';
import 'package:jam_sync/features/score_canvas/widgets/playback/playback_section_widget.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class PlaybackCanvas extends ConsumerStatefulWidget {
  final String projectID;
  final String canvasID;
  final double scrollOffset;
  final int currentIndex;
  final String zoomMode;
  final bool isPlaying;

  const PlaybackCanvas({
    super.key,
    required this.projectID,
    required this.canvasID,
    required this.scrollOffset,
    required this.currentIndex,
    required this.zoomMode,
    required this.isPlaying,
  });

  @override
  ConsumerState<PlaybackCanvas> createState() => _PlaybackCanvasState();
}

class _PlaybackCanvasState extends ConsumerState<PlaybackCanvas> {
  Map<String, int> sectionRowCount = {};

  void computeSectionRowCount(List<SectionModel> sections) {
    sectionRowCount = {
      for (final section in sections)
        section.id: (section.barCount / PlaybackLayout.barsPerRow).ceil(),
    };
  }

  int rowsBeforeSection(SectionModel targetSection, List<SectionModel> sections) {
    int rows = 0;
    for (final section in sections) {
      if (section.id == targetSection.id) break;
      rows += sectionRowCount[section.id] ?? 0;
    }
    return rows;
  }

  ({SectionModel section, int rowIndex, int barWithinRow}) locateBar(
    int barIndex,
    List<SectionModel> sections,
  ) {
    int barCursor = 0;
    for (final section in sections) {
      final barCount = section.barCount;
      if (barIndex < barCursor + barCount) {
        final barWithinSection = barIndex - barCursor;
        final rowIndex = barWithinSection ~/ PlaybackLayout.barsPerRow;
        final barWithinRow = barWithinSection % PlaybackLayout.barsPerRow;
        return (section: section, rowIndex: rowIndex, barWithinRow: barWithinRow);
      }
      barCursor += barCount;
    }
    return (section: sections.last, rowIndex: 0, barWithinRow: 0);
  }

  double computeCursorY(int barIndex, List<SectionModel> sections) {
    if (sections.isEmpty) return 0;

    final location = locateBar(barIndex, sections);

    double y = 0;
    for (final section in sections) {
      if (section.id == location.section.id) break;
      final sectionRows = sectionRowCount[section.id] ?? 0;
      y += PlaybackLayout.sectionHeaderHeight +
          12 +
          sectionRows * PlaybackLayout.rowHeight +
          PlaybackLayout.sectionSpacing;
    }

    y += PlaybackLayout.sectionHeaderHeight + 12 + location.rowIndex * PlaybackLayout.rowHeight;

    return y + (PlaybackLayout.barHeight / 2);
  }

  double computeCursorX(int colIndex) {
    return colIndex * PlaybackLayout.barWidth + (PlaybackLayout.barWidth / 2);
  }

  @override
  Widget build(BuildContext context) {
    final sectionAsync = ref.watch(
      sectionsStreamProvider((projectID: widget.projectID, canvasID: widget.canvasID)),
    );

    final canvasAsync = ref.watch(canvasesStreamProvider(widget.projectID));
    final canvases = canvasAsync.value ?? [];
    final currentCanvas = canvases.where((c) => c.id == widget.canvasID).firstOrNull;
    final timeSignature = currentCanvas?.timeSignature ?? "4/4";

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

        computeSectionRowCount(sections);

        final barIndex = widget.currentIndex;
        final location = locateBar(barIndex, sections);
        final cursorY = computeCursorY(barIndex, sections);
        final cursorX = computeCursorX(location.barWithinRow);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(PlaybackLayout.canvasPadding),
          child: SizedBox(
            width: PlaybackLayout.canvasWidth,
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections.map((section) {
                    return PlaybackSectionWidget(
                      projectID: widget.projectID,
                      canvasID: widget.canvasID,
                      timeSignature: timeSignature,
                      section: section,
                      isFirst: section == sections.first,
                      barWidth: PlaybackLayout.barWidth,
                    );
                  }).toList(),
                ),
                Positioned(
                  left: cursorX - (PlaybackLayout.cursorWidth / 2),
                  top: cursorY - (PlaybackLayout.barHeight / 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: PlaybackCursor(
                      barHeight: PlaybackLayout.barHeight,
                      isPlaying: widget.isPlaying,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

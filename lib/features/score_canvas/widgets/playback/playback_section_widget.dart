import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/features/score_canvas/widgets/bar_widget.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class PlaybackSectionWidget extends ConsumerWidget {
  final String projectID;
  final String canvasID;
  final String timeSignature;
  final SectionModel section;
  final bool isFirst;
  final double barWidth;
  final double canvasWidth;
  final bool isEditable;
  final int currentBeatIndex;
  final Map<int, int> barIndexMap;

  final int sectionStartBarIndex;
  final double beatPosition;

  const PlaybackSectionWidget({
    super.key,
    required this.projectID,
    required this.canvasID,
    required this.timeSignature,
    required this.section,
    this.isFirst = false,
    required this.barWidth,
    required this.canvasWidth,
    this.isEditable = true,
    this.currentBeatIndex = -1,
    this.barIndexMap = const {},
    this.sectionStartBarIndex = 0,
    this.beatPosition = -1,
  });

  static const double sectionHeaderHeight = 44;
  static const double barHeight = 60;
  static const double runSpacing = 8;
  static const int barsPerRow = 4;

  int computeRowCount(int barCount) {
    return (barCount / barsPerRow).ceil();
  }

  double cursorProgress(int barStartBeat, int barEndBeat) {
    if (beatPosition < 0) return 0.0;
    if (beatPosition < barStartBeat || beatPosition >= barEndBeat) return 0.0;

    final beatsInBar = barEndBeat - barStartBeat;
    if (beatsInBar <= 0) return 0.0;

    return ((beatPosition - barStartBeat) / beatsInBar).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barsAsync = ref.watch(
      barsStreamProvider((projectID: projectID, canvasID: canvasID, sectionID: section.id)),
    );

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 16),
      child: SizedBox(
        width: canvasWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppStyles.darkNavy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                section.name,
                style: AppStyles.bodySmall(context).copyWith(color: AppStyles.white),
              ),
            ),
            12.height,
            barsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ),
              data: (bars) {
                if (bars.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No bars in this section',
                      style: AppStyles.bodyMedium(context).copyWith(color: AppStyles.grey400),
                    ),
                  );
                }

                final rows = <Widget>[];
                final totalBars = bars.length;

                for (int rowStart = 0; rowStart < totalBars; rowStart += barsPerRow) {
                  final rowBars = bars.sublist(
                    rowStart,
                    rowStart + barsPerRow > totalBars ? totalBars : rowStart + barsPerRow,
                  );

                  rows.add(
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: rowStart + barsPerRow < totalBars ? runSpacing : 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(barsPerRow, (i) {
                          final isLeft = i % 4 == 0;
                          final isRight = i % 4 == 3 || i == bars.length - 1;
                          
                          if (i < rowBars.length) {
                            final bar = rowBars[i];
                            final globalBarIndex = sectionStartBarIndex + rowStart + i;

                            final barStartBeat =
                                barIndexMap[globalBarIndex] ?? (globalBarIndex * 4);
                            final barEndBeat = barIndexMap[globalBarIndex + 1] ?? barStartBeat + 4;
                            final isHighlighted =
                                currentBeatIndex >= barStartBeat && currentBeatIndex < barEndBeat;
                            final beatIndexWithinBar = isHighlighted
                                ? (currentBeatIndex - barStartBeat)
                                : -1;

                            return SizedBox(
                              width: barWidth,
                              child: BarWidget(
                                projectID: projectID,
                                canvasID: canvasID,
                                sectionID: section.id,
                                barID: bar.id,
                                timeSig: timeSignature,
                                chords: bar.chords,
                                passingChords: bar.passingChord,
                                isCornerLeft: isLeft,
                                isCornerRight: isRight,
                                isEditable: isEditable,
                                isHighlighted: isHighlighted,
                                highlightedBeatIndex: beatIndexWithinBar,
                                isCursorBar: isHighlighted,
                                cursorProgress: cursorProgress(barStartBeat, barEndBeat),
                              ),
                            );
                          } else {
                            return SizedBox(width: barWidth);
                          }
                        }),
                      ),
                    ),
                  );
                }

                return Column(children: rows);
              },
            ),
          ],
        ),
      ),
    );
  }
}

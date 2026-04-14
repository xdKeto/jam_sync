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

  const PlaybackSectionWidget({
    super.key,
    required this.projectID,
    required this.canvasID,
    required this.timeSignature,
    required this.section,
    this.isFirst = false,
    required this.barWidth,
  });

  static const double sectionHeaderHeight = 44;
  static const double barHeight = 60;
  static const double runSpacing = 8;
  static const int barsPerRow = 4;

  int computeRowCount(int barCount) {
    return (barCount / barsPerRow).ceil();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barsAsync = ref.watch(
      barsStreamProvider((projectID: projectID, canvasID: canvasID, sectionID: section.id)),
    );

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 16),
      child: SizedBox(
        width: 1000, 
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
                    rowStart + barsPerRow > totalBars
                        ? totalBars
                        : rowStart + barsPerRow,
                  );

                  rows.add(
                    Padding(
                      padding: EdgeInsets.only(bottom: rowStart + barsPerRow < totalBars ? runSpacing : 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(barsPerRow, (i) {
                          if (i < rowBars.length) {
                            final bar = rowBars[i];
                            final barIndex = rowStart + i;
                            final isFirstBar = barIndex == 0;
                            final isLastBarInRow = (i == barsPerRow - 1) || (barIndex == totalBars - 1);

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
                                isCornerLeft: isFirstBar && i == 0,
                                isCornerRight: isLastBarInRow && i == rowBars.length - 1,
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

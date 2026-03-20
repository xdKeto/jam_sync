import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/features/score_canvas/widgets/bar_widget.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class SectionWidget extends ConsumerWidget {
  final String projectId;
  final String canvasId;
  final String timeSignature;
  final SectionModel section;
  final bool isFirst;
  final double barWidth;

  const SectionWidget({
    super.key,
    required this.projectId,
    required this.canvasId,
    required this.timeSignature,
    required this.section,
    this.isFirst = false,
    required this.barWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barsAsync = ref.watch(barsStreamProvider((
      projectId: projectId,
      canvasId: canvasId,
      sectionId: section.id,
    )));

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppStyles.darkNavy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              section.name,
              style: AppStyles.bodyMedium(context).copyWith(color: AppStyles.white),
            ),
          ),
          const SizedBox(height: 12),
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

              final barWidgets = List.generate(bars.length, (i) {
                final bar = bars[i];
                final isLeft = i % 4 == 0;
                final isRight = i % 4 == 3 || i == bars.length - 1;

                return SizedBox(
                  width: barWidth,
                  child: BarWidget(
                    timeSig: timeSignature,
                    chords: bar.chords,
                    isCornerLeft: isLeft,
                    isCornerRight: isRight,
                  ),
                );
              });

              return Wrap(runSpacing: 8, children: barWidgets);
            },
          ),
        ],
      ),
    );
  }
}

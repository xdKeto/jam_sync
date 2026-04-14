import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/features/score_canvas/providers/participants_provider.dart';
import 'package:jam_sync/features/score_canvas/widgets/bar_widget.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class SectionWidget extends ConsumerWidget {
  final String projectID;
  final String canvasID;
  final String timeSignature;
  final SectionModel section;
  final bool isFirst;
  final double barWidth;

  const SectionWidget({
    super.key,
    required this.projectID,
    required this.canvasID,
    required this.timeSignature,
    required this.section,
    this.isFirst = false,
    required this.barWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barsAsync = ref.watch(
      barsStreamProvider((projectID: projectID, canvasID: canvasID, sectionID: section.id)),
    );

    final participantsAsync = ref.watch(participantsStreamProvider(projectID));

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 16.0),
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

              final participants = participantsAsync.value ?? [];
              final sortedOnline = participants.where((p) => p.isOnline).toList()
                ..sort((a, b) => a.uid.compareTo(b.uid));

              final barWidgets = List.generate(bars.length, (i) {
                final bar = bars[i];
                final isLeft = i % 4 == 0;
                final isRight = i % 4 == 3 || i == bars.length - 1;

                // Highlight calculation moved to BarWidget for performance

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
                    sortedParticipants: sortedOnline,
                    onChordChanged: (beatIndex, chord) {
                      ref
                          .read(projectRepositoryProvider)
                          .updateBarChord(
                            projectID: projectID,
                            canvasID: canvasID,
                            sectionID: section.id,
                            barID: bar.id,
                            beatIndex: beatIndex,
                            chord: chord,
                            userID: FirebaseAuth.instance.currentUser!.uid,
                          );
                    },
                    onChordDeleted: (beatIndex) {
                      ref
                          .read(projectRepositoryProvider)
                          .deleteBarChord(
                            projectID: projectID,
                            canvasID: canvasID,
                            sectionID: section.id,
                            barID: bar.id,
                            beatIndex: beatIndex,
                            userID: FirebaseAuth.instance.currentUser!.uid,
                          );
                    },
                    onPassingChordChanged: (beatIndex, chord) {
                      ref
                          .read(projectRepositoryProvider)
                          .updatePassingChord(
                            projectID: projectID,
                            canvasID: canvasID,
                            sectionID: section.id,
                            barID: bar.id,
                            beatIndex: beatIndex,
                            chord: chord,
                            userID: FirebaseAuth.instance.currentUser!.uid,
                          );
                    },
                    onPassingChordDeleted: (beatIndex) {
                      ref
                          .read(projectRepositoryProvider)
                          .deletePassingChord(
                            projectID: projectID,
                            canvasID: canvasID,
                            sectionID: section.id,
                            barID: bar.id,
                            beatIndex: beatIndex,
                            userID: FirebaseAuth.instance.currentUser!.uid,
                          );
                    },
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

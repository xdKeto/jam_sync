import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:jam_sync/features/score_canvas/providers/editing_presence_provider.dart';
import 'package:jam_sync/shared/models/participant_info_model.dart';
import 'package:jam_sync/shared/utils/collab_colors.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/features/score_canvas/widgets/chord_widget.dart';
import 'package:jam_sync/features/score_canvas/widgets/circle_of_fifths_dialog.dart';
import 'package:jam_sync/features/score_canvas/widgets/chord_modifier_dialog.dart';
import 'package:jam_sync/features/score_canvas/widgets/chord_action_sheet.dart';

class BarWidget extends ConsumerWidget {
  const BarWidget({
    super.key,
    this.projectID,
    this.canvasID,
    this.sectionID,
    this.barID,
    this.chords,
    this.timeSig = '4/4',
    this.passingChords,
    this.isCornerRight = false,
    this.isCornerLeft = false,
    this.sortedParticipants,
    this.onChordChanged,
    this.onChordDeleted,
    this.onPassingChordChanged,
    this.onPassingChordDeleted,
    this.isEditable = true,
    this.isHighlighted = false,
    this.highlightedBeatIndex = -1,
    this.isCursorBar = false,
    this.cursorProgress = 0.0,
  });

  final String? projectID;
  final String? canvasID;
  final String? sectionID;
  final String? barID;
  final List<String>? chords;
  final String timeSig;
  final List<String>? passingChords;
  final bool isCornerRight;
  final bool isCornerLeft;
  final List<ParticipantInfo>? sortedParticipants;
  final void Function(int beatIndex, String chord)? onChordChanged;
  final void Function(int beatIndex)? onChordDeleted;
  final void Function(int beatIndex, String chord)? onPassingChordChanged;
  final void Function(int beatIndex)? onPassingChordDeleted;
  final bool isEditable;
  final bool isHighlighted;
  final int highlightedBeatIndex;
  final bool isCursorBar;
  final double cursorProgress;

  Future<void> showChordPickerFlow(
    BuildContext context,
    int beatIndex,
    String mainChord,
    String passingChord,
  ) async {
    final String? pId = projectID;
    final String? cId = canvasID;
    final String? sId = sectionID;
    final String? bId = barID;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (pId != null && cId != null && sId != null && bId != null && userId != null) {
      // ignore: unawaited_futures
      FirebaseDatabase.instance.ref('playback_sessions/$pId/editing/$userId').set({
        'barPath': '$cId/$sId/$bId',
        'beatIndex': beatIndex,
        'timestamp': ServerValue.timestamp,
      });
    }

    final action = await ChordActionSheet.show(
      context,
      currentChord: mainChord,
      currentPassingChord: passingChord,
    );

    Future<void> clearEditingPresence() async {
      if (pId != null && userId != null) {
        await FirebaseDatabase.instance.ref('playback_sessions/$pId/editing/$userId').remove();
      }
    }

    if (action == null || !context.mounted) {
      await clearEditingPresence();
      return;
    }

    switch (action) {
      case ChordAction.addChord:
      case ChordAction.changeChord:
        while (true) {
          if (!context.mounted) break;
          final result = await CircleOfFifthsDialog.show(context);
          if (result == null || !context.mounted) break;
          final (rootNote, isMinor) = result;
          final finalChord = await ChordModifierDialog.show(context, rootNote, isMinor: isMinor);
          if (finalChord == '__BACK__') continue;
          if (finalChord != null && onChordChanged != null) {
            onChordChanged!(beatIndex, finalChord);
          }
          break;
        }
        break;
      case ChordAction.deleteChord:
        if (onChordDeleted != null) onChordDeleted!(beatIndex);
        break;
      case ChordAction.addPassing:
      case ChordAction.changePassing:
        while (true) {
          if (!context.mounted) break;
          final result = await CircleOfFifthsDialog.show(context);
          if (result == null || !context.mounted) break;
          final (rootNote, isMinor) = result;
          final finalChord = await ChordModifierDialog.show(context, rootNote, isMinor: isMinor);
          if (finalChord == '__BACK__') continue;
          if (finalChord != null && onPassingChordChanged != null) {
            onPassingChordChanged!(beatIndex, finalChord);
          }
          break;
        }
        break;
      case ChordAction.deletePassing:
        if (onPassingChordDeleted != null) onPassingChordDeleted!(beatIndex);
        break;
    }

    await clearEditingPresence();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color? beatHighlightColor;
    int? editorBeatIndex;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final double barHeight = 60;

    if (projectID != null && canvasID != null && sectionID != null && barID != null) {
      final barPath = '$canvasID/$sectionID/$barID';
      // listen ke provider editnig presence
      final editorData = ref.watch(
        editingPresenceProvider(projectID!).select((presence) {
          final data = presence.value ?? {};
          for (final i in data.entries) {
            if (i.key != currentUserId && i.value.barPath == barPath) {
              return (uid: i.key, beatIndex: i.value.beatIndex); //id user, index yg lagi diedit
            }
          }
          return null;
        }),
      );

      // warna editing sesuai index
      if (editorData != null && sortedParticipants != null) {
        final index = sortedParticipants!.indexWhere((p) => p.uid == editorData.uid);
        if (index != -1) {
          beatHighlightColor = CollabColors.getColor(index);
          editorBeatIndex = editorData.beatIndex;
        }
      }
    }

    // time sig
    final parts = timeSig.split('/');
    final defaultBeats = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 4) : 4;
    final int beats = (chords != null && chords!.isNotEmpty) ? chords!.length : defaultBeats;

    final Color barColor = AppStyles.white;
    final Color borderColor = AppStyles.black;
    final double borderWidth = 1.0;
    final double barWidth = 250.0;

    return Material(
      color: barColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: borderWidth),
        borderRadius: (isCornerRight && isCornerLeft)
            ? const BorderRadius.all(Radius.circular(12))
            : isCornerRight
            ? const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              )
            : isCornerLeft
            ? const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))
            : BorderRadius.zero,
      ),
      child: SizedBox(
        height: barHeight,
        child: Stack(
          children: [
            Row(
              children: List.generate(beats, (index) {
                String rawMainChord = '';
                if (chords != null && index < chords!.length) {
                  rawMainChord = chords![index];
                }

                String passingChord = '';
                if (passingChords != null && index < passingChords!.length) {
                  passingChord = passingChords![index];
                }

                // highlighting beat, collaborative, hijau playback
                final isPlaybackHighlighted = isHighlighted && index == highlightedBeatIndex;
                final isEditingHighlighted = index == editorBeatIndex && beatHighlightColor != null;
                final Color beatBackground = isEditingHighlighted
                    ? beatHighlightColor.withValues(alpha: 0.3)
                    : isPlaybackHighlighted
                    ? AppStyles.success.withValues(alpha: 0.3)
                    : Colors.transparent;

                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: (isCornerRight && isCornerLeft)
                          ? const BorderRadius.all(Radius.circular(12))
                          : (isCornerRight && index == beats - 1)
                          ? const BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            )
                          : (isCornerLeft && index == 0)
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            )
                          : BorderRadius.zero,
                      color: beatBackground,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // main chord
                        Positioned.fill(
                          child: isEditable
                              ? Builder(
                                  builder: (innerContext) => InkWell(
                                    onTap: () => showChordPickerFlow(
                                      innerContext,
                                      index,
                                      rawMainChord,
                                      passingChord,
                                    ),
                                    child: ChordWidget(chord: rawMainChord),
                                  ),
                                )
                              : ChordWidget(chord: rawMainChord),
                        ),
                        // passing chord
                        if (passingChord.isNotEmpty)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: isEditable
                                ? Builder(
                                    builder: (innerContext) => InkWell(
                                      onTap: () => showChordPickerFlow(
                                        innerContext,
                                        index,
                                        rawMainChord,
                                        passingChord,
                                      ),
                                      child: ChordWidget(chord: passingChord, isPassing: true),
                                    ),
                                  )
                                : ChordWidget(chord: passingChord, isPassing: true),
                          ),
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: AppStyles.grey600,
                            ),
                          ),
                        ),
                        if (index < beats - 1)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 1, color: AppStyles.grey400),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            // cursor widget
            if (isCursorBar)
              Positioned(
                left: cursorProgress * barWidth - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: AppStyles.black),
              ),
          ],
        ),
      ),
    );
  }
}

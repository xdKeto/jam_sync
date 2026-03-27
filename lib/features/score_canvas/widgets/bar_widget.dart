import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/features/score_canvas/widgets/chord_widget.dart';
import 'package:jam_sync/features/score_canvas/widgets/circle_of_fifths_dialog.dart';
import 'package:jam_sync/features/score_canvas/widgets/chord_modifier_dialog.dart';
import 'package:jam_sync/features/score_canvas/widgets/chord_action_sheet.dart';

class BarWidget extends StatelessWidget {
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
    this.highlightColor,
    this.onChordChanged,
    this.onChordDeleted,
    this.onPassingChordChanged,
    this.onPassingChordDeleted,
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
  final Color? highlightColor;
  final void Function(int beatIndex, String chord)? onChordChanged;
  final void Function(int beatIndex)? onChordDeleted;
  final void Function(int beatIndex, String chord)? onPassingChordChanged;
  final void Function(int beatIndex)? onPassingChordDeleted;

  Future<void> showChordPickerFlow(BuildContext context, int beatIndex, String mainChord, String passingChord) async {
    final String? pId = projectID;
    final String? cId = canvasID;
    final String? sId = sectionID;
    final String? bId = barID;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (pId != null && cId != null && sId != null && bId != null && userId != null) {
      await FirebaseDatabase.instance.ref('playback_sessions/$pId/editing/$userId').set({
        'barPath': '$cId/$sId/$bId',
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
  Widget build(BuildContext context) {
    int beats = 4;
    final parts = timeSig.split('/');
    if (parts.isNotEmpty) {
      beats = int.tryParse(parts[0]) ?? 4;
    }

    return Material(
      color: highlightColor?.withValues(alpha: 0.15) ?? AppStyles.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: highlightColor ?? AppStyles.black, 
          width: highlightColor != null ? 2.5 : 1,
        ),
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
        height: 60,
        child: Row(
          children: List.generate(beats, (index) {
            String rawMainChord = '';
            if (chords != null && index < chords!.length) {
              rawMainChord = chords![index];
            }

            String passingChord = '';
            if (passingChords != null && index < passingChords!.length) {
              passingChord = passingChords![index];
            }

            return Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main Chord
                  Positioned.fill(
                    child: Builder(
                      builder: (innerContext) => InkWell(
                        onTap: () => showChordPickerFlow(innerContext, index, rawMainChord, passingChord),
                        child: ChordWidget(chord: rawMainChord),
                      ),
                    ),
                  ),
                  // Passing Chord
                  if (passingChord.isNotEmpty)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Builder(
                        builder: (innerContext) => InkWell(
                          onTap: () => showChordPickerFlow(innerContext, index, rawMainChord, passingChord),
                          child: ChordWidget(chord: passingChord, isPassing: true),
                        ),
                      ),
                    ),
                  // Garis pembatas tipis antar beat
                  if (index < beats - 1)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 1, color: AppStyles.grey400),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/features/score_canvas/widgets/chord_widget.dart';
import 'package:jam_sync/features/score_canvas/widgets/circle_of_fifths_dialog.dart';
import 'package:jam_sync/features/score_canvas/widgets/chord_modifier_dialog.dart';

class BarWidget extends StatelessWidget {
  const BarWidget({
    super.key,
    this.chords,
    this.timeSig = '4/4',
    this.passingChords,
    this.isCornerRight = false,
    this.isCornerLeft = false,
  });

  final List<String>? chords;
  final String timeSig;
  final List<String>? passingChords;
  final bool isCornerRight;
  final bool isCornerLeft;

  Future<void> showChordPickerFlow(BuildContext context, String currentChord) async {
    final renderBox = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlay),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final bool hasChord = currentChord.isNotEmpty;

    final action = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppStyles.darkNavy,
      items: [
        PopupMenuItem(
          value: 'add_change',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(hasChord ? Icons.swap_horiz : Icons.add, color: AppStyles.white, size: 18),
              const SizedBox(width: 8),
              Text(
                hasChord ? 'Change' : 'Add',
                style: const TextStyle(color: AppStyles.white, fontSize: 14),
              ),
            ],
          ),
        ),
        if (hasChord)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit, color: AppStyles.white, size: 18),
                const SizedBox(width: 8),
                Text('Edit', style: const TextStyle(color: AppStyles.white, fontSize: 14)),
              ],
            ),
          ),
      ],
    );

    if (action == null || !context.mounted) return;

    // Loop allows back navigation from modifier → circle of fifths
    while (true) {
      final result = await CircleOfFifthsDialog.show(context);
      if (result == null || !context.mounted) return;
      final (rootNote, isMinor) = result;

      final finalChord = await ChordModifierDialog.show(context, rootNote, isMinor: isMinor);
      if (finalChord == '__BACK__') continue; // back to circle of fifths
      if (finalChord != null) {
        debugPrint('✅ Chord selected: $finalChord');
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    int beats = 4;
    final parts = timeSig.split('/');
    if (parts.isNotEmpty) {
      beats = int.tryParse(parts[0]) ?? 4;
    }

    return Material(
      color: AppStyles.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppStyles.black, width: 1),
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
                        onTap: () => showChordPickerFlow(innerContext, rawMainChord),
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
                          onTap: () => showChordPickerFlow(innerContext, passingChord),
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

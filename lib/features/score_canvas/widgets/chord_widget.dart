import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class ChordWidget extends StatelessWidget {
  const ChordWidget({
    super.key,
    required this.chord,
    this.isPassing = false,
  });

  final String chord;
  final bool isPassing;

  List<InlineSpan> buildChordSpans(BuildContext context) {
    if (chord.isEmpty) return [const TextSpan(text: '')];

    final double baseSize = isPassing ? 14 : 24;
    final double accidentalSize = isPassing ? 12 : 16;
    final double modifierSize = isPassing ? 10 : 14;
    final Color textColor = isPassing ? AppStyles.textSecondary : AppStyles.textPrimary;

    List<InlineSpan> spans = [];
    for (int i = 0; i < chord.length; i++) {
      String char = chord[i];

      // A-G atau / (bass note separator) -> teks besar
      if (RegExp(r'[A-G/]').hasMatch(char)) {
        spans.add(
          TextSpan(
            text: char,
            style: (isPassing ? AppStyles.labelSmall(context) : AppStyles.h3(context)).copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: baseSize,
            ),
          ),
        );
      }
      // # (sharp) atau b (flat) -> agak ke atas dan lebih rapat (nyelip)
      else if (char == '#' || char == 'b') {
        final displayChar = char == '#' ? '♯' : '♭';
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Transform.translate(
              offset: Offset(0, isPassing ? 0 : 2),
              child: Text(
                displayChar,
                style: AppStyles.h4(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: accidentalSize,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ),
        );
      }
      // Modifiers lainnya (m, dim, maj, 7, dll) -> normal, teks kecil
      else {
        spans.add(
          TextSpan(
            text: char,
            style: AppStyles.h4(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: textColor, fontSize: modifierSize),
          ),
        );
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (isPassing) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: RichText(
          text: TextSpan(children: buildChordSpans(context)),
        ),
      );
    }

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: RichText(
            text: TextSpan(children: buildChordSpans(context)),
          ),
        ),
      ),
    );
  }
}

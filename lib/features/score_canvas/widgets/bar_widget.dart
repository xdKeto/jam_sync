import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

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

  // Render chord characters with intelligent sizing and vertical alignment
  List<InlineSpan> _buildChordSpans(BuildContext context, String chord, {bool isPassing = false}) {
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
                  letterSpacing: -1.0, // Negatif agar modifier setelahnya nyelip
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
    // Menentukan jumlah beat (kolom) dalam satu bar berdasarkan time signature
    int beats = 4;
    final parts = timeSig.split('/');
    if (parts.isNotEmpty) {
      beats = int.tryParse(parts[0]) ?? 4;
    }

    return Container(
      height: 60, // Tinggi tetap untuk konsistensi bar
      decoration: BoxDecoration(
        color: AppStyles.white,
        border: Border.all(color: AppStyles.black, width: 1),
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
      child: Row(
        // Membagi ruang bar menjadi kolom-kolom (beats) yang sama besar
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
                // Render Main Chord di tengah block-nya menggunakan RichText
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: RichText(
                        text: TextSpan(children: _buildChordSpans(context, rawMainChord)),
                      ),
                    ),
                  ),
                ),
                // Render Passing Chord agak ke atas dan di pojok kanan block
                if (passingChord.isNotEmpty)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RichText(
                        text: TextSpan(
                          children: _buildChordSpans(context, passingChord, isPassing: true),
                        ),
                      ),
                    ),
                  ),
                // Garis pembatas tipis antar beat / chord full dari atas ke bawah
                if (index < beats - 1)
                  Positioned(
                    right: 0,
                    top: 0, // Sentuh border atas
                    bottom: 0, // Sentuh border bawah
                    child: Container(width: 1, color: AppStyles.grey400),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

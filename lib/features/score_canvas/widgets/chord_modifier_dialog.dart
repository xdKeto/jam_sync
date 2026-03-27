import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/features/score_canvas/widgets/bass_note_dialog.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class ChordModifierDialog extends StatefulWidget {
  const ChordModifierDialog({super.key, required this.rootNote, required this.isMinor});

  final String rootNote;
  final bool isMinor;

  static Future<String?> show(BuildContext context, String rootNote, {bool isMinor = false}) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chord Modifier',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: ChordModifierDialog(rootNote: rootNote, isMinor: isMinor),
        );
      },
    );
  }

  @override
  State<ChordModifierDialog> createState() => _ChordModifierDialogState();
}

class _ChordModifierDialogState extends State<ChordModifierDialog> {
  int? selectedIndex;
  int? hoveredIndex;
  String? bassNote;

  static const List<String> majorModifierLabels = [
    '',
    'Maj7',
    '7',
    'm7',
    'dim',
    'aug',
    'sus2',
    'sus4',
    'add9',
    '6',
    '9',
    '/',
  ];
  static const List<String> majorModifierDisplay = [
    'None',
    'Maj7',
    '7',
    'm7',
    'dim',
    'aug',
    'sus2',
    'sus4',
    'add9',
    '6',
    '9',
    '/',
  ];

  static const List<String> minorModifierLabels = [
    '',
    '7',
    'dim',
    'aug',
    'sus2',
    'sus4',
    'add9',
    '6',
    '9',
    '11',
    'b5',
    '/',
  ];
  static const List<String> minorModifierDisplay = [
    'None',
    '7',
    'dim',
    'aug',
    'sus2',
    'sus4',
    'add9',
    '6',
    '9',
    '11',
    '♭5',
    '/',
  ];

  List<String> get modifierLabels => widget.isMinor ? minorModifierLabels : majorModifierLabels;
  List<String> get modifierDisplay => widget.isMinor ? minorModifierDisplay : majorModifierDisplay;

  String get displayRoot => widget.rootNote.replaceAll('#', '♯').replaceAll('b', '♭');

  String get currentChordDisplay {
    if (selectedIndex == null || modifierLabels[selectedIndex!].isEmpty) {
      return displayRoot;
    }
    if (modifierLabels[selectedIndex!] == '/' && bassNote != null) {
      final displayBass = bassNote!.replaceAll('#', '♯').replaceAll('b', '♭');
      return '$displayRoot/$displayBass';
    }
    if (modifierLabels[selectedIndex!] == '/') {
      return '$displayRoot/...';
    }
    return '$displayRoot${modifierLabels[selectedIndex!]}';
  }

  String get resultChord {
    if (selectedIndex == null || modifierLabels[selectedIndex!].isEmpty) {
      return widget.rootNote;
    }
    if (modifierLabels[selectedIndex!] == '/' && bassNote != null) {
      return '${widget.rootNote}/$bassNote';
    }
    return '${widget.rootNote}${modifierLabels[selectedIndex!]}';
  }

  @override
  Widget build(BuildContext context) {
    const double size = 320;
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTapDown: (details) => handleTap(details.localPosition, size),
              onPanUpdate: (details) => handleHover(details.localPosition, size),
              onPanEnd: (_) => setState(() => hoveredIndex = null),
              child: CustomPaint(
                size: const Size(size, size),
                painter: ModifierRingPainter(
                  selectedIndex: selectedIndex,
                  hoveredIndex: hoveredIndex,
                  displayLabels: modifierDisplay,
                ),
              ),
            ),
            IgnorePointer(
              ignoring: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Back button
                  SizedBox(
                    height: 28,
                    width: 28,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop('__BACK__'),
                      icon: const Icon(Icons.arrow_back, color: AppStyles.white, size: 16),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: AppStyles.grey600,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                  4.height,
                  Text(
                    currentChordDisplay,
                    style: const TextStyle(
                      color: AppStyles.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  6.height,
                  SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(resultChord);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.mediumBlue,
                        foregroundColor: AppStyles.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void handleHover(Offset position, double size) {
    final idx = hitTest(position, size);
    setState(() => hoveredIndex = idx);
  }

  void handleTap(Offset position, double size) async {
    final idx = hitTest(position, size);
    if (idx != null) {
      setState(() => selectedIndex = idx);
      if (modifierLabels[idx] == '/') {
        final selected = await BassNoteDialog.show(context);
        if (selected != null && context.mounted) {
          setState(() => bassNote = selected);
        }
      }
    }
  }

  int? hitTest(Offset position, double size) {
    final center = Offset(size / 2, size / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.52;

    if (distance < innerRadius || distance > outerRadius) return null;

    double angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;
    final segmentAngle = 2 * pi / 12;
    return ((angle + segmentAngle / 2) % (2 * pi) / segmentAngle).floor();
  }
}

class ModifierRingPainter extends CustomPainter {
  final int? selectedIndex;
  final int? hoveredIndex;
  final List<String> displayLabels;

  ModifierRingPainter({this.selectedIndex, this.hoveredIndex, required this.displayLabels});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.52;
    final segmentCount = displayLabels.length;
    final segmentAngle = 2 * pi / segmentCount;
    final startOffset = -pi / 2 - segmentAngle / 2;

    for (int i = 0; i < segmentCount; i++) {
      final startAngle = startOffset + i * segmentAngle;
      final isSelected = selectedIndex == i;
      final isHovered = hoveredIndex == i;

      Color segColor;
      if (isSelected) {
        segColor = AppStyles.skyBlue;
      } else if (isHovered) {
        segColor = AppStyles.mediumBlue.withValues(alpha: 0.6);
      } else {
        segColor = AppStyles.grey200;
      }

      final paint = Paint()
        ..color = segColor
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(
          center.dx + innerRadius * cos(startAngle),
          center.dy + innerRadius * sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerRadius),
          startAngle,
          segmentAngle,
          false,
        )
        ..lineTo(
          center.dx + innerRadius * cos(startAngle + segmentAngle),
          center.dy + innerRadius * sin(startAngle + segmentAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle + segmentAngle,
          -segmentAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..color = AppStyles.grey400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(path, borderPaint);

      final midAngle = startAngle + segmentAngle / 2;
      final textRadius = (outerRadius + innerRadius) / 2;
      final textPos = Offset(
        center.dx + textRadius * cos(midAngle),
        center.dy + textRadius * sin(midAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: displayLabels[i],
          style: TextStyle(
            color: isSelected || isHovered ? AppStyles.white : AppStyles.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, textPos - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // Center hole
    final corePaint = Paint()
      ..color = AppStyles.darkNavy
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, corePaint);
  }

  @override
  bool shouldRepaint(covariant ModifierRingPainter oldDelegate) {
    return selectedIndex != oldDelegate.selectedIndex || hoveredIndex != oldDelegate.hoveredIndex;
  }
}

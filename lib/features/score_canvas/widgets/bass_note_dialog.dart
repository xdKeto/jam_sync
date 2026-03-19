import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class BassNoteDialog extends StatefulWidget {
  const BassNoteDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Bass Note',
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
        return const Center(child: BassNoteDialog());
      },
    );
  }

  @override
  State<BassNoteDialog> createState() => _BassNoteDialogState();
}

class _BassNoteDialogState extends State<BassNoteDialog> {
  int? hoveredIndex;

  static const List<String> bassNotes = [
    'C', 'G', 'D', 'A', 'E', 'B',
    'F♯', 'C♯', 'G♯', 'E♭', 'B♭', 'F',
  ];

  String noteToDataString(String display) {
    return display.replaceAll('♯', '#').replaceAll('♭', 'b');
  }

  @override
  Widget build(BuildContext context) {
    const double size = 280;
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
                painter: BassNoteRingPainter(hoveredIndex: hoveredIndex),
              ),
            ),
            // Center: back button + label
            IgnorePointer(
              ignoring: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 28,
                    width: 28,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: const Icon(Icons.arrow_back, color: AppStyles.white, size: 16),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: AppStyles.grey600,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select\nBass',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppStyles.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                      height: 1.3,
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

  void handleTap(Offset position, double size) {
    final idx = hitTest(position, size);
    if (idx != null) {
      Navigator.of(context).pop(noteToDataString(bassNotes[idx]));
    }
  }

  int? hitTest(Offset position, double size) {
    final center = Offset(size / 2, size / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.48;

    if (distance < innerRadius || distance > outerRadius) return null;

    double angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;
    final segmentAngle = 2 * pi / 12;
    return ((angle + segmentAngle / 2) % (2 * pi) / segmentAngle).floor();
  }
}

class BassNoteRingPainter extends CustomPainter {
  final int? hoveredIndex;

  BassNoteRingPainter({this.hoveredIndex});

  static const List<String> bassNotes = [
    'C', 'G', 'D', 'A', 'E', 'B',
    'F♯', 'C♯', 'G♯', 'E♭', 'B♭', 'F',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.48;
    final segmentAngle = 2 * pi / 12;
    final startOffset = -pi / 2 - segmentAngle / 2;

    for (int i = 0; i < 12; i++) {
      final startAngle = startOffset + i * segmentAngle;
      final isHovered = hoveredIndex == i;

      final paint = Paint()
        ..color = isHovered ? AppStyles.skyBlue : AppStyles.grey200
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx + innerRadius * cos(startAngle), center.dy + innerRadius * sin(startAngle))
        ..arcTo(Rect.fromCircle(center: center, radius: outerRadius), startAngle, segmentAngle, false)
        ..lineTo(center.dx + innerRadius * cos(startAngle + segmentAngle), center.dy + innerRadius * sin(startAngle + segmentAngle))
        ..arcTo(Rect.fromCircle(center: center, radius: innerRadius), startAngle + segmentAngle, -segmentAngle, false)
        ..close();

      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..color = AppStyles.grey400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(path, borderPaint);

      final midAngle = startAngle + segmentAngle / 2;
      final textRadius = (outerRadius + innerRadius) / 2;
      final textPos = Offset(center.dx + textRadius * cos(midAngle), center.dy + textRadius * sin(midAngle));

      final textPainter = TextPainter(
        text: TextSpan(
          text: bassNotes[i],
          style: TextStyle(
            color: isHovered ? AppStyles.white : AppStyles.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
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
  bool shouldRepaint(covariant BassNoteRingPainter oldDelegate) {
    return hoveredIndex != oldDelegate.hoveredIndex;
  }
}

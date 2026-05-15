import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class CircleOfFifthsDialog extends StatefulWidget {
  const CircleOfFifthsDialog({super.key});

  static Future<(String, bool)?> show(BuildContext context) {
    return showGeneralDialog<(String, bool)>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Circle of Fifths',
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
        return const Center(child: CircleOfFifthsDialog());
      },
    );
  }

  @override
  State<CircleOfFifthsDialog> createState() => _CircleOfFifthsDialogState();
}

class _CircleOfFifthsDialogState extends State<CircleOfFifthsDialog> {
  int? hoveredOuterIndex;
  int? hoveredInnerIndex;

  static const List<String> outerNotes = [
    'C',
    'G',
    'D',
    'A',
    'E',
    'B',
    'F♯',
    'C♯',
    'G♯',
    'E♭',
    'B♭',
    'F',
  ];

  static const List<String> innerNotes = [
    'Am',
    'Em',
    'Bm',
    'F♯m',
    'C♯m',
    'G♯m',
    'E♭m',
    'B♭m',
    'Fm',
    'Cm',
    'Gm',
    'Dm',
  ];

  String noteToDataString(String display) {
    return display.replaceAll('♯', '#').replaceAll('♭', 'b');
  }

  @override
  Widget build(BuildContext context) {
    const double size = 320;
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: size,
        height: size,
        child: GestureDetector(
          onTapDown: (details) => handleTap(details.localPosition, size),
          onPanUpdate: (details) => handleHover(details.localPosition, size),
          onPanEnd: (_) => setState(() {
            hoveredOuterIndex = null;
            hoveredInnerIndex = null;
          }),
          child: CustomPaint(
            size: const Size(size, size),
            painter: CircleOfFifthsPainter(
              hoveredOuterIndex: hoveredOuterIndex,
              hoveredInnerIndex: hoveredInnerIndex,
            ),
          ),
        ),
      ),
    );
  }

  void handleHover(Offset position, double size) {
    final result = hitTest(position, size);
    setState(() {
      hoveredOuterIndex = result.$1;
      hoveredInnerIndex = result.$2;
    });
  }

  void handleTap(Offset position, double size) {
    final result = hitTest(position, size);
    if (result.$1 != null) {
      final note = noteToDataString(outerNotes[result.$1!]);
      Navigator.of(context).pop((note, false));
    } else if (result.$2 != null) {
      final note = noteToDataString(innerNotes[result.$2!]);
      Navigator.of(context).pop((note, true));
    }
  }

  (int?, int?) hitTest(Offset position, double size) {
    final center = Offset(size / 2, size / 2);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final outerRadius = size / 2;
    final innerRadius = outerRadius * 0.68;
    final coreRadius = innerRadius * 0.55;

    double angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;
    final segmentAngle = 2 * pi / 12;
    int index = ((angle + segmentAngle / 2) % (2 * pi) / segmentAngle).floor();

    if (distance >= innerRadius && distance <= outerRadius) {
      return (index, null);
    } else if (distance >= coreRadius && distance < innerRadius) {
      return (null, index);
    }
    return (null, null);
  }
}

class CircleOfFifthsPainter extends CustomPainter {
  final int? hoveredOuterIndex;
  final int? hoveredInnerIndex;

  CircleOfFifthsPainter({this.hoveredOuterIndex, this.hoveredInnerIndex});

  static const List<String> outerNotes = [
    'C',
    'G',
    'D',
    'A',
    'E',
    'B',
    'F♯',
    'C♯',
    'G♯',
    'E♭',
    'B♭',
    'F',
  ];

  static const List<String> innerNotes = [
    'Am',
    'Em',
    'Bm',
    'F♯m',
    'C♯m',
    'G♯m',
    'E♭m',
    'B♭m',
    'Fm',
    'Cm',
    'Gm',
    'Dm',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.68;
    final coreRadius = innerRadius * 0.55;

    final segmentAngle = 2 * pi / 12;
    final startOffset = -pi / 2 - segmentAngle / 2;

    // outer
    for (int i = 0; i < 12; i++) {
      final startAngle = startOffset + i * segmentAngle;
      final isHovered = hoveredOuterIndex == i;

      final paint = Paint()
        ..color = isHovered ? AppStyles.skyBlue : AppStyles.grey200
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

      // label
      final midAngle = startAngle + segmentAngle / 2;
      final textRadius = (outerRadius + innerRadius) / 2;
      final textPos = Offset(
        center.dx + textRadius * cos(midAngle),
        center.dy + textRadius * sin(midAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: outerNotes[i],
          style: TextStyle(
            color: isHovered ? AppStyles.white : AppStyles.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, textPos - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // inner
    for (int i = 0; i < 12; i++) {
      final startAngle = startOffset + i * segmentAngle;
      final isHovered = hoveredInnerIndex == i;

      final paint = Paint()
        ..color = isHovered ? AppStyles.darkNavy : AppStyles.grey300
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx + coreRadius * cos(startAngle), center.dy + coreRadius * sin(startAngle))
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle,
          segmentAngle,
          false,
        )
        ..lineTo(
          center.dx + coreRadius * cos(startAngle + segmentAngle),
          center.dy + coreRadius * sin(startAngle + segmentAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: coreRadius),
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

      // label
      final midAngle = startAngle + segmentAngle / 2;
      final textRadius = (innerRadius + coreRadius) / 2;
      final textPos = Offset(
        center.dx + textRadius * cos(midAngle),
        center.dy + textRadius * sin(midAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: innerNotes[i],
          style: TextStyle(
            color: isHovered ? AppStyles.white : AppStyles.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, textPos - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // center
    final corePaint = Paint()
      ..color = AppStyles.darkNavy
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, coreRadius, corePaint);

    // label
    final centerText = TextPainter(
      text: const TextSpan(
        text: 'Select\nRoot',
        style: TextStyle(
          color: AppStyles.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    centerText.paint(canvas, center - Offset(centerText.width / 2, centerText.height / 2));
  }

  @override
  bool shouldRepaint(covariant CircleOfFifthsPainter oldDelegate) {
    return hoveredOuterIndex != oldDelegate.hoveredOuterIndex ||
        hoveredInnerIndex != oldDelegate.hoveredInnerIndex;
  }
}

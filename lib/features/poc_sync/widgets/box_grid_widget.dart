import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class BoxGridWidget extends StatelessWidget {
  const BoxGridWidget({super.key, required this.currentBox});

  final int currentBox;
  static const int totalBoxes = 64;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: List.generate(totalBoxes, (index) {
        final isActive = index == currentBox;
        final isPassed = index < currentBox;

        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? AppStyles.success
                : isPassed
                ? AppStyles.success.withValues(alpha: 0.3)
                : AppStyles.grey200,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive || isPassed ? Colors.white : Colors.black54,
              ),
            ),
          ),
        );
      }),
    );
  }
}

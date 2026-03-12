import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class PocBoxGridWidget extends StatelessWidget {
  const PocBoxGridWidget({
    super.key,
    required this.currentBox,
    required this.progress,
  });

  final int currentBox;
  final double progress;
  static const int totalBox = 64;
  static const int boxPerRow = 16;
  static const double boxSize = 40;
  static const double spacing = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitBoxesPerRow = (constraints.maxWidth / (boxSize + spacing))
            .floor();
        final totalRows = (totalBox / fitBoxesPerRow).ceil();
        // final rowWidth = fitBoxesPerRow * (boxSize + spacing);
        // final totalRowWidth = fitBoxesPerRow * (boxSize + spacing) - spacing;
        // final centerOffset = (constraints.maxWidth - totalRowWidth) / 2;

        // posisi cursosr
        final totalProgress = progress * totalBox;
        final currentRow = (totalProgress / fitBoxesPerRow).floor();

        // kalo box ngga ful
        final boxesInCurrentRow = (currentRow < totalRows - 1)
            ? fitBoxesPerRow
            : totalBox - (currentRow * fitBoxesPerRow);
        final currentRowWidth =
            boxesInCurrentRow * (boxSize + spacing) - spacing;
        final currentCenterOffset =
            (constraints.maxWidth - currentRowWidth) / 2;
        final progressRow = (totalProgress % fitBoxesPerRow) / boxesInCurrentRow;

        return Stack(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(totalBox, (index) {
                final isActive = index == currentBox;
                final isPassed = index < currentBox;

                return Container(
                  width: boxSize,
                  height: boxSize,
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
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive || isPassed
                            ? Colors.white
                            : Colors.black54,
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (progress > 0 && progress < 1.0)
              Positioned(
                top: currentRow * (boxSize + spacing),
                left: currentCenterOffset + (progressRow * currentRowWidth),
                child: Container(
                  width: 5,
                  height: boxSize,
                  color: AppStyles.black,
                ),
              ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/features/score_canvas/widgets/section_widget.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class CanvasWidget extends ConsumerStatefulWidget {
  final String projectId;
  final String canvasId;
  final String timeSignature;

  const CanvasWidget({
    super.key,
    required this.projectId,
    required this.canvasId,
    required this.timeSignature,
  });

  @override
  ConsumerState<CanvasWidget> createState() => CanvasWidgetState();
}

class CanvasWidgetState extends ConsumerState<CanvasWidget> {
  final TransformationController transformController = TransformationController();
  final GlobalKey canvasKey = GlobalKey();
  bool isClamping = false;
  Size viewportSize = Size.zero;

  static const double canvasWidth = 1000;
  static const double canvasBarWidth = canvasWidth / 4;
  static const double canvasPadding = 16.0;
  static const double totalCanvasWidth = canvasWidth + canvasPadding * 2;

  @override
  void initState() {
    super.initState();
    transformController.addListener(onTransformChanged);
  }

  @override
  void dispose() {
    transformController.removeListener(onTransformChanged);
    transformController.dispose();
    super.dispose();
  }

  double getCanvasContentHeight() {
    final renderBox = canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      return renderBox.size.height;
    }
    return 300;
  }

  void onTransformChanged() {
    if (isClamping || viewportSize == Size.zero) return;

    final matrix = transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    double tx = matrix[12];
    double ty = matrix[13];

    final scaledW = totalCanvasWidth * scale;
    final scaledH = getCanvasContentHeight() * scale;

    double clampedTx = tx;
    double clampedTy = ty;

    if (scaledW <= viewportSize.width) {
      clampedTx = 0;
    } else {
      clampedTx = tx.clamp(-(scaledW - viewportSize.width), 0.0);
    }

    if (scaledH <= viewportSize.height) {
      clampedTy = 0;
    } else {
      clampedTy = ty.clamp(-(scaledH - viewportSize.height), 0.0);
    }

    if (clampedTx != tx || clampedTy != ty) {
      isClamping = true;
      final newMatrix = matrix.clone();
      newMatrix[12] = clampedTx;
      newMatrix[13] = clampedTy;
      transformController.value = newMatrix;
      isClamping = false;
    }
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.music_square, size: 64, color: AppStyles.grey400),
          const SizedBox(height: 16),
          Text(
            'Empty Canvas, create new section!',
            style: AppStyles.h3(context).copyWith(color: AppStyles.grey400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(sectionsStreamProvider((
      projectId: widget.projectId,
      canvasId: widget.canvasId,
    )));

    return sectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (sections) {
        if (sections.isEmpty) {
          return buildEmptyState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
            final minScale = (viewportSize.width / totalCanvasWidth).clamp(0.1, 1.0);

            return InteractiveViewer(
              transformationController: transformController,
              minScale: minScale,
              maxScale: 2.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              interactionEndFrictionCoefficient: 0.0000135,
              scaleFactor: 200,
              constrained: false,
              child: Padding(
                key: canvasKey,
                padding: const EdgeInsets.all(canvasPadding),
                child: SizedBox(
                  width: canvasWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(sections.length, (i) {
                      return SectionWidget(
                        projectId: widget.projectId,
                        canvasId: widget.canvasId,
                        timeSignature: widget.timeSignature,
                        section: sections[i],
                        isFirst: i == 0,
                        barWidth: canvasBarWidth,
                      );
                    }),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

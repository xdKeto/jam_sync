import 'package:flutter/material.dart';
import 'package:jam_sync/features/score_canvas/widgets/bar_widget.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class CanvasWidget extends StatefulWidget {
  const CanvasWidget({super.key});

  @override
  State<CanvasWidget> createState() => CanvasWidgetState();
}

class CanvasWidgetState extends State<CanvasWidget> {
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
    return 300; // fallback estimate
  }

  List<Widget> generateDummySections() {
    final List<Map<String, dynamic>> dummySections = [
      {
        'title': 'Intro',
        'bars': [
          {
            'c': ['C', '', 'G', ''],
            'p': ['', '', 'G/B', ''],
          },
          {
            'c': ['Am', '', 'F', ''],
          },
          {
            'c': ['C', '', 'G', ''],
          },
          {
            'c': ['Am', '', 'F', ''],
          },
          {
            'c': ['C', '', 'G', ''],
          },
          {
            'c': ['Am', '', 'F', ''],
          },
        ],
      },
      {
        'title': 'Verse 1',
        'bars': [
          {
            'c': ['C', '', '', ''],
          },
          {
            'c': ['G', '', '', ''],
          },
          {
            'c': ['Am', '', '', ''],
          },
          {
            'c': ['F', '', '', ''],
          },
          {
            'c': ['C', '', '', ''],
          },
          {
            'c': ['G', '', '', ''],
          },
          {
            'c': ['Am', '', '', ''],
          },
          {
            'c': ['F', '', 'G', ''],
          },
        ],
      },
      {
        'title': 'Pre-Chorus',
        'bars': [
          {
            'c': ['Dm', '', 'Em', ''],
          },
          {
            'c': ['F', '', 'G', ''],
          },
          {
            'c': ['Dm', '', 'Em', ''],
          },
          {
            'c': ['F', '', 'G', 'G7'],
          },
        ],
      },
      {
        'title': 'Chorus 1',
        'bars': [
          {
            'c': ['C', '', 'G', ''],
          },
          {
            'c': ['Am', '', 'F', ''],
          },
          {
            'c': ['C', '', 'E7', ''],
          },
          {
            'c': ['Am', '', 'F', ''],
          },
          {
            'c': ['C', '', 'G', ''],
          },
          {
            'c': ['Am', '', 'F', ''],
          },
          {
            'c': ['C', '', 'G', ''],
          },
          {
            'c': ['C', '', '', ''],
          },
        ],
      },
      {
        'title': 'Interlude',
        'bars': [
          {
            'c': ['Am', 'G', 'F', 'C'],
            'p': ['', 'G/B', '', 'C/E'],
          },
          {
            'c': ['Dm', 'C', 'G', ''],
            'p': ['', 'C/E', 'G7', ''],
          },
          {
            'c': ['Am', 'G', 'F', 'C'],
          },
          {
            'c': ['D/F#', '', 'F', 'G'],
          },
        ],
      },
      {
        'title': 'Chorus 2',
        'bars': [
          {
            'c': ['C', '', 'G', ''],
          },
          {
            'c': ['Am', '', 'F', ''],
          },
          {
            'c': ['C', '', 'E7', ''],
          },
          {
            'c': ['Am', '', 'F', ''],
          },
          {
            'c': ['C', '', 'G', ''],
          },
          {
            'c': ['Am', '', 'F', ''],
          },
          {
            'c': ['C', '', 'G', ''],
          },
          {
            'c': ['C', '', '', ''],
          },
        ],
      },
      {
        'title': 'Outro',
        'bars': [
          {
            'c': ['F', 'G', 'Am', 'C'],
          },
          {
            'c': ['Dm', 'Em', 'F', 'G'],
          },
          {
            'c': ['Am', 'Cmaj7', 'F', 'G#dim'],
            'p': ['', 'G', '', ''],
          },
          {
            'c': ['C', '', '', ''],
          },
        ],
      },
    ];

    List<Widget> sectionWidgets = [];

    for (int s = 0; s < dummySections.length; s++) {
      final section = dummySections[s];
      final title = section['title'] as String;
      final barsData = section['bars'] as List<Map<String, dynamic>>;

      List<Widget> barWidgets = [];
      for (int i = 0; i < barsData.length; i++) {
        final data = barsData[i];
        final isLeft = i % 4 == 0;
        final isRight = i % 4 == 3 || i == barsData.length - 1;

        barWidgets.add(
          SizedBox(
            width: canvasBarWidth,
            child: BarWidget(
              timeSig: '4/4',
              chords: List<String>.from(data['c']),
              passingChords: data.containsKey('p') ? List<String>.from(data['p']) : null,
              isCornerLeft: isLeft,
              isCornerRight: isRight,
            ),
          ),
        );
      }

      // Use AppStyles if available, otherwise fallback
      sectionWidgets.add(
        Padding(
          padding: EdgeInsets.only(top: s == 0 ? 0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppStyles.darkNavy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  title,
                  style: AppStyles.bodyMedium(context).copyWith(color: AppStyles.white),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(runSpacing: 8, children: barWidgets),
            ],
          ),
        ),
      );
    }
    return sectionWidgets;
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

    // Horizontal: pin left, can't drag past right edge
    if (scaledW <= viewportSize.width) {
      clampedTx = 0;
    } else {
      clampedTx = tx.clamp(-(scaledW - viewportSize.width), 0.0);
    }

    // Vertical: pin top, can't drag past bottom edge
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Dynamic minScale: zoom out sampai canvas pas di viewport width
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
                children: generateDummySections(),
              ),
            ),
          ),
        );
      },
    );
  }
}

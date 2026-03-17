import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/features/score_canvas/widgets/bar_widget.dart';

class ScoreCanvasScreen extends StatefulWidget {
  const ScoreCanvasScreen({super.key});

  @override
  State<ScoreCanvasScreen> createState() => _ScoreCanvasScreenState();
}

class _ScoreCanvasScreenState extends State<ScoreCanvasScreen> {
  final TransformationController _transformController = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();
  bool _isClamping = false;
  Size _viewportSize = Size.zero;

  static const double canvasWidth = 1000;
  static const double canvasBarWidth = canvasWidth / 4;
  static const double _canvasPadding = 16.0;
  static const double _totalCanvasWidth = canvasWidth + _canvasPadding * 2;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  double _getCanvasContentHeight() {
    final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      return renderBox.size.height;
    }
    return 300; // fallback estimate
  }

  List<Widget> _generateDummyBars() {
    final List<Map<String, dynamic>> rawChords = [
      // Intro
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
      // Verse 1
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
      // Pre-Chorus
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
      // Chorus 1
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
      // Interlude
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
      // Chorus 2
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
      // Outro
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
    ];

    List<Widget> bars = [];
    for (int i = 0; i < rawChords.length; i++) {
      final data = rawChords[i];
      final isLeft = i % 4 == 0;
      final isRight = i % 4 == 3 || i == rawChords.length - 1;

      bars.add(
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
    return bars;
  }

  void _onTransformChanged() {
    if (_isClamping || _viewportSize == Size.zero) return;

    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    double tx = matrix[12];
    double ty = matrix[13];

    final scaledW = _totalCanvasWidth * scale;
    final scaledH = _getCanvasContentHeight() * scale;

    double clampedTx = tx;
    double clampedTy = ty;

    // Horizontal: pin left, can't drag past right edge
    if (scaledW <= _viewportSize.width) {
      clampedTx = 0;
    } else {
      clampedTx = tx.clamp(-(scaledW - _viewportSize.width), 0.0);
    }

    // Vertical: pin top, can't drag past bottom edge
    if (scaledH <= _viewportSize.height) {
      clampedTy = 0;
    } else {
      clampedTy = ty.clamp(-(scaledH - _viewportSize.height), 0.0);
    }

    if (clampedTx != tx || clampedTy != ty) {
      _isClamping = true;
      final newMatrix = matrix.clone();
      newMatrix[12] = clampedTx;
      newMatrix[13] = clampedTy;
      _transformController.value = newMatrix;
      _isClamping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text("Score Canvas", style: AppStyles.h2(context)),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

                  // Dynamic minScale: zoom out sampai canvas pas di viewport width
                  final minScale = (_viewportSize.width / _totalCanvasWidth).clamp(0.1, 1.0);

                  return InteractiveViewer(
                    transformationController: _transformController,
                    minScale: minScale,
                    maxScale: 2.0,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    interactionEndFrictionCoefficient: 0.0000135,
                    scaleFactor: 200,
                    constrained: false,
                    child: Padding(
                      key: _canvasKey,
                      padding: const EdgeInsets.all(_canvasPadding),
                      child: SizedBox(
                        width: canvasWidth,
                        child: Wrap(runSpacing: 8, children: _generateDummyBars()),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

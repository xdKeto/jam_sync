import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/playback_layout.dart';

enum PlaybackZoomMode { widthToWidth, cursorToFollow }

class ZoomController extends ChangeNotifier {
  ScrollController? vScrollController;
  ScrollController? hScrollController;

  PlaybackZoomMode mode = PlaybackZoomMode.widthToWidth;
  double screenWidth = 0;
  double screenHeight = 0;
  // double lastAutoScrollTime = 0;
  static const int delay = 3000;
  bool isScrolling = false;
  Timer? timer;

  void onScroll() {
    isScrolling = true;
    timer?.cancel();
    timer = Timer(Duration(milliseconds: delay), () {
      isScrolling = false;
    });
  }

  // controller
  // ScrollController? get _vScrollController => vScrollController;
  // ScrollController? get _hScrollController => hScrollController;
  // PlaybackZoomMode get _mode => mode;

  void initVScrollController(ScrollController controller) {
    vScrollController?.removeListener(onScroll);
    vScrollController = controller;
    vScrollController?.addListener(onScroll);
  }

  void initHScrollController(ScrollController controller) {
    hScrollController?.removeListener(onScroll);
    hScrollController = controller;
    hScrollController?.addListener(onScroll);
  }

  void disposeControllers() {
    vScrollController?.removeListener(onScroll);
    hScrollController?.removeListener(onScroll);
    vScrollController = null;
    hScrollController = null;
  }

  void updateScreenSize(double width, double height) {
    screenWidth = width;
    screenHeight = height;

    final newMode = width >= 600 ? PlaybackZoomMode.widthToWidth : PlaybackZoomMode.cursorToFollow;
    if (newMode != mode) {
      mode = newMode;
      notifyListeners();
    }
  }

  void scrollTo(double target, bool isVertical) {
    final controller = isVertical ? vScrollController : hScrollController;
    if (controller == null || !controller.hasClients) return;
    if (!isVertical && mode != PlaybackZoomMode.cursorToFollow) return;

    final maxScroll = controller.position.maxScrollExtent;
    final clampTarget = target.clamp(0.0, maxScroll);
    final offset = controller.offset;

    if ((clampTarget - offset).abs() < 1) return;
    if (isScrolling) return;

    controller.animateTo(
      clampTarget,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void scrollToBar({required double cursor, required bool isVertical}) {
    final ratio = isVertical ? 0.33 : 0.5;

    final target = cursor - ((isVertical ? screenHeight : screenWidth) * ratio);
    scrollTo(target, isVertical);
  }

  // helper
  double get canvasWidth {
    return mode == PlaybackZoomMode.widthToWidth ? screenWidth : PlaybackLayout.canvasWidth;
  }

  bool get isHorizontalScroll {
    return mode == PlaybackZoomMode.cursorToFollow;
  }

  @override
  void dispose() {
    timer?.cancel();
    disposeControllers();
    super.dispose();
  }
}

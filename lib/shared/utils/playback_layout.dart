/// single source of truth untuk semua layout
abstract final class PlaybackLayout {
  static const double canvasWidth = 1000;
  static const double barWidth = canvasWidth / 4;       // 250
  static const double barHeight = 60;
  static const double sectionHeaderHeight = 44;
  static const double sectionSpacing = 16;
  static const double runSpacing = 8;
  static const int barsPerRow = 4;
  static const double rowHeight = barHeight + runSpacing; // 68
  static const double cursorWidth = 8;
  static const double canvasPadding = 16;
}

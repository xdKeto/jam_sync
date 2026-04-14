import 'dart:ui';

import 'package:jam_sync/shared/models/bar_model.dart';
import 'package:jam_sync/shared/models/section_model.dart';

int timeSignatureHelper(String timeSignature) {
  final split = timeSignature.split('/');
  return int.parse(split[0]);
}

/// buat beat map,
/// output: 0:4, 1:4, 2:4, dst
Map<int, int> beatMapHelper(
  List<SectionModel> sections,
  Map<String, List<BarModel>> barsSection,
  String timeSignature,
) {
  final beatsPerBarValue = timeSignatureHelper(timeSignature);
  final result = <int, int>{};

  int cumulativeBeats = 0;
  int barIndex = 0;

  for (final section in sections) {
    final bars = barsSection[section.id] ?? [];

    for (final bar in bars) {
      // beatCount: if bar has chords, use chord count; else use timeSignature default
      final beatCount = bar.chords.isNotEmpty ? bar.chords.length : beatsPerBarValue;

      result[barIndex] = cumulativeBeats;
      cumulativeBeats += beatCount;
      barIndex++;
    }
  }

  return result;
}

/// cari bar index berdasarkan beat
int findBarSectionHelper(double beats, Map<int, int> beatMap) {
  if (beatMap.isEmpty) return -1;

  List<int> keys = beatMap.keys.toList()..sort();
  int left = 0;
  int right = keys.length - 1;

  if (beats < 0) return -1;

  // binary searchhh
  int result = -1;
  while (left <= right) {
    int mid = left + (right - left) ~/ 2;
    int midKey = keys[mid];
    int midValue = beatMap[midKey]!;

    if (midValue <= beats) {
      result = midKey; 
      left = mid + 1;
    } else {
      right = mid - 1;
    }
  }

  return result;
}

/// total durasi partitur
int totalDurationHelper(
  List<SectionModel> sections,
  Map<String, List<BarModel>> barsSection,
  String timeSignature,
  double tempo,
) {
  final beatMap = beatMapHelper(sections, barsSection, timeSignature);
  if (beatMap.isEmpty) return 0;

  final lastBarIndex = beatMap.keys.reduce((a, b) => a > b ? a : b);
  final totalBeats = beatMap[lastBarIndex]!;

  // durasi
  final beatDurationMs = 60000 / tempo;
  return (totalBeats * beatDurationMs).round();
}

/// hitung posisi cursor berdasarkan partitur
Offset barPixelPosition({
  required int barIndex,
  double barWidth = 250,
  double barHeight = 60,
  double runSpacing = 8,
  double sectionHeaderHeight = 44,
  int barsPerRow = 4,
}) {
  final rowHeight = barHeight + runSpacing;
  final row = barIndex ~/ barsPerRow;
  final col = barIndex % barsPerRow;

  return Offset(
    col * barWidth + barWidth / 2,        // x: tengah bar
    sectionHeaderHeight + (row * rowHeight) + (barHeight / 2), // y: tengah bar
  );
}

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef NTPSample = ({int offset, int rtt, int timestamp});

// providers
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  service.initService();
  ref.onDispose(() => service.dispose());
  return service;
});

final resyncProvider = Provider<ResyncService>((ref) {
  final syncRef = ref.read(syncServiceProvider);
  final service = ResyncService(syncRef);
  ref.onDispose(() => service.dispose());
  return service;
});

class SyncService {
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
  StreamSubscription? offsetSubscription;
  int serverTimeOffset = 0;

  // background calibration stuff
  List<NTPSample> offsetHistory = [];
  Timer? bgTimer;
  static const int history = 80;
  static const int interval = 21000;
  bool isQuick = false;

  // toggle dev tool, ntp
  static const bool useNtp = true;

  void initService() {
    if (!useNtp) {
      offsetSubscription?.cancel();
      offsetSubscription = rtdb.child('.info/serverTimeOffset').onValue.listen((event) {
        serverTimeOffset = (event.snapshot.value as int?) ?? 0;
        // print("server offset: $serverTimeOffset");
      });

      return;
    }

    // start background calibration
    bgTimer = Timer.periodic(Duration(milliseconds: interval), (_) => backgroundCalibrate());

    backgroundCalibrate();
  }

  void dispose() {
    bgTimer?.cancel();
    bgTimer = null;
    offsetHistory.clear();
  }

  Future<void> backgroundCalibrate() async {
    for (int i = 0; i < 2; i++) {
      final sample = await calculateNTP();
      if (sample.rtt > 200) return; // quality gate
      if (offsetHistory.length >= history) offsetHistory.removeAt(0);

      offsetHistory.add(sample);
      updateHistory();

      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  Future<void> quickCalibrate() async {
    if (isQuick) return;
    isQuick = true;

    try {
      final samples = <({int offset, int rtt, int timestamp})>[];

      // sample 3x
      for (int i = 0; i < 3; i++) {
        final sample = await calculateNTP();
        samples.add(sample);

        await Future.delayed(Duration(milliseconds: 300));
      }

      // sort that shitttt
      samples.sort((a, b) => a.rtt.compareTo(b.rtt));
      final best = samples.take(2).toList();
      final offset = best.map((e) => e.offset).reduce((a, b) => a + b) ~/ best.length;
      final rtt = best.map((e) => e.rtt).reduce((a, b) => a + b) / best.length;

      // diff
      final difference = (offset - serverTimeOffset).abs();

      // gabungin offset background + quick calibrate
      if (difference > 10 && rtt < 200) {
        serverTimeOffset = ((serverTimeOffset * 0.7) + (offset * 0.3)).round();
        debugPrint('blend 70/30 offset');
      } else {
        debugPrint('blend skipped');
      }
    } finally {
      isQuick = false;
    }
  }

  Future<({int offset, int rtt, int timestamp})> calculateNTP() async {
    final tSend = DateTime.now().millisecondsSinceEpoch;
    final ping = rtdb.child('_ping').push();
    await ping.set(ServerValue.timestamp);

    final pingValue = await ping.get();
    final tReceive = DateTime.now().millisecondsSinceEpoch;
    final serverTime = pingValue.value as int;

    final rtt = tReceive - tSend;
    final offset = serverTime - tSend - (rtt ~/ 2);

    await ping.remove();
    return (offset: offset, rtt: rtt, timestamp: DateTime.now().millisecondsSinceEpoch);
  }

  void updateHistory() {
    if (offsetHistory.isEmpty) return;

    final sorted = List<NTPSample>.from(offsetHistory)
      ..sort((a, b) => a.offset.compareTo(b.offset));
    final median = sorted.length ~/ 2;
    serverTimeOffset = sorted[median].offset;
  }

  int getEstimatedServerTime() {
    return DateTime.now().millisecondsSinceEpoch + serverTimeOffset;
  }
}

class ResyncService {
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
  final SyncService service;

  ResyncService(this.service);

  void broadcastPosition(String roomID, int serverStartTime, {int delay = 2000}) {
    Future.delayed(Duration(milliseconds: delay), () {
      final now = service.getEstimatedServerTime();
      final position = now - serverStartTime;

      rtdb.child('playback_sessions/$roomID/startupCorrection').set({
        'positionMs': position,
        'broadcastTime': now,
      });

      debugPrint('broadcast: $position');
    });
  }

  void broadcastHalfway(String roomID, int position, int broadcastTime) {
    rtdb.child('playback_sessions/$roomID/halfwayCorrection').set({
      'positionMs': position,
      'broadcastTime': broadcastTime,
    });

    debugPrint('broadcast halfway: $position, $broadcastTime');
  }

  void listenPosition(
    String roomID,
    bool isHalfway,
    Function(int position, int broadcastTime) callback,
  ) {
    StreamSubscription? subscription;
    bool isReceived = false;

    subscription = rtdb
        .child('playback_sessions/$roomID/${isHalfway ? 'halfwayCorrection' : 'startupCorrection'}')
        .onValue
        .listen((event) {
          if (!event.snapshot.exists) return; //skip stale
          if (isReceived) return;
          isReceived = true;

          final data = event.snapshot.value as Map<String, dynamic>;
          final position = data['positionMs'] as int;
          final broadcastTime = data['broadcastTime'] as int;

          callback(position, broadcastTime);
          subscription?.cancel();
        });

    // timeout kalo ga dapet-dapet
    Future.delayed(Duration(seconds: 3), () {
      if (!isReceived) {
        subscription?.cancel();
        debugPrint('resync timeout..');
      }
    });
  }

  void dispose() {}
}

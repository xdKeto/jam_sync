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

  List<NTPSample> offsetHistory = [];
  Timer? bgTimer;
  static const int history = 40;
  static const int interval = 15000;
  static const int minSample = 7;

  void initService() {
    // offsetSubscription?.cancel();
    // offsetSubscription = rtdb.child('.info/serverTimeOffset').onValue.listen((event) {
    //   serverTimeOffset = (event.snapshot.value as int?) ?? 0;
    //   // print("server offset: $serverTimeOffset");
    // });
    // return;

    // 
    burstCalibrate();
  }

  void dispose() {
    bgTimer?.cancel();
    bgTimer = null;
    offsetHistory.clear();
  }

  int getEstimatedServerTime() {
    // debugPrint(serverTimeOffset.toString());R
    return DateTime.now().millisecondsSinceEpoch + serverTimeOffset;
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
    return (
      offset: offset,
      rtt: rtt,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  //in room 
  void startBackgroundCalibration() {
    if (bgTimer != null) return;
    bgTimer = Timer.periodic(
      Duration(milliseconds: interval),
      (_) => backgroundCalibrate(),
    );
  }

  void pauseBackgroundCalibration() {
    bgTimer?.cancel();
    bgTimer = null;
  }

  Future<void> backgroundCalibrate() async {
    for (int i = 0; i < 2; i++) {
      final sample = await calculateNTP();
      if (sample.rtt > 200) return; // quality gate
      if (offsetHistory.length >= history) offsetHistory.removeAt(0);

      debugPrint('background calibrate ${i + 1} triggered');
      offsetHistory.add(sample);
      updateHistory();

      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  // on start
  Future<void> burstCalibrate() async {
    for (int i = 0; i < 6; i++) {
      final sample = await calculateNTP();

      // quality gate, kalo sample pertama > 200 tetep masukin
      if (sample.rtt > 200) {
        if (offsetHistory.isEmpty) {
          offsetHistory.add(sample);
        }
        continue;
      }

      debugPrint('burst calibrate ${i + 1} triggered');
      offsetHistory.add(sample);
      updateHistory();

      await Future.delayed(Duration(milliseconds: 300));
    }
  }

  // final calibration
  Future<void> smartQuickCalibrate() async {
    if (offsetHistory.length < minSample) {
      await multiSampleCalibrate();
    } else {
      await quickCalibrate();
    }
  }

  // kurang sample, ambil 8
  Future<void> multiSampleCalibrate() async {
    try {
      final samples = <NTPSample>[];

      for (int i = 0; i < 10; i++) {
        final sample = await calculateNTP();
        if (sample.rtt <= 300) {
          samples.add(sample);
        }
        await Future.delayed(Duration(milliseconds: 200));
      }

      if (samples.isEmpty) {
        debugPrint('multiSampleCalibrate: no valid samples');
        return;
      }

      samples.sort((a, b) => a.rtt.compareTo(b.rtt));
      final topSamples = samples.take((samples.length * 0.8).ceil()).toList();

      topSamples.sort((a, b) => a.offset.compareTo(b.offset));
      final medianOffset = topSamples[topSamples.length ~/ 2].offset;

      // blend
      serverTimeOffset = ((serverTimeOffset * 0.5) + (medianOffset * 0.5))
          .round();
    } finally {}
  }

  // sample cukup, ambil 2
  Future<void> quickCalibrate() async {
    try {
      final samples = <({int offset, int rtt, int timestamp})>[];

      for (int i = 0; i < 3; i++) {
        final sample = await calculateNTP();
        samples.add(sample);

        await Future.delayed(Duration(milliseconds: 300));
      }
      
      samples.sort((a, b) => a.rtt.compareTo(b.rtt));
      final best = samples.take(2).toList();

      // mean sample
      final offset =
          best.map((e) => e.offset).reduce((a, b) => a + b) ~/ best.length; // total / len
      final rtt = best.map((e) => e.rtt).reduce((a, b) => a + b) / best.length;

      final difference = (offset - serverTimeOffset).abs();

      // blend offset, kalo diff nya gede aja
      // if (difference > 10 && rtt < 200) {
      if (difference < 15 && rtt < 150) {
        serverTimeOffset = ((serverTimeOffset * 0.7) + (offset * 0.3))
            .round(); //blend 70/30
        debugPrint('blend 70/30 offset');
      } else {
        debugPrint('blend skipped');
      }
    } finally {}
  }

  void updateHistory() {
    if (offsetHistory.isEmpty) return;

    // sort
    final sorted = List<NTPSample>.from(offsetHistory)
      ..sort((a, b) => a.offset.compareTo(b.offset));
    final median = sorted.length ~/ 2;

    serverTimeOffset = sorted[median].offset; //median
  }
}

class ResyncService {
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
  final SyncService service;

  ResyncService(this.service);

  // leader broadcast
  void broadcastPosition(
    String roomID,
    int serverStartTime, {
    int delay = 2000,
  }) {
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

  // member listen
  void listenPosition(
    String roomID,
    bool isHalfway,
    Function(int position, int broadcastTime) callback, {
    Duration? timeout,
  }) {
    StreamSubscription? subscription;
    bool isReceived = false;

    subscription = rtdb
        .child(
          'playback_sessions/$roomID/${isHalfway ? 'halfwayCorrection' : 'startupCorrection'}',
        )
        .onValue
        .listen((event) {
          if (!event.snapshot.exists) return; //skip stale
          if (isReceived) return;
          isReceived = true;

          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          final position = data['positionMs'] as int;
          final broadcastTime = data['broadcastTime'] as int;

          callback(position, broadcastTime);
          subscription?.cancel();
        });

    if (timeout != null) {
      Future.delayed(timeout, () {
        if (!isReceived) {
          subscription?.cancel();
          debugPrint('resync timeout..');
        }
      });
    }
  }

  void dispose() {}
}

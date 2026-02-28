import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pocSyncServiceProvider = Provider<PocSyncService>((ref) {
  final service = PocSyncService();
  service.initService();
  ref.onDispose(() => service.dispose());
  return service;
});

class PocSyncService {
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
  StreamSubscription? subOffset;
  int serverTimeOffset = 0;

  // ===== TOGGLE: ganti true/false untuk testing =====
  // true = pakai NTP multi-sample, false = pakai Firebase .info/serverTimeOffset
  static const bool useNtpCalibration = true;
  // ================================================

  void initService() {
    if (useNtpCalibration) return; // skip Firebase offset, pakai NTP nanti

    subOffset?.cancel();
    subOffset = rtdb.child('.info/serverTimeOffset').onValue.listen((event) {
      serverTimeOffset = (event.snapshot.value as int?) ?? 0;
      print("server offset: $serverTimeOffset");
    });
  }
  // void initService() {
  //   subOffset?.cancel();
  //   subOffset = rtdb.child('.info/serverTimeOffset').onValue.listen((event) {
  //     final raw = (event.snapshot.value as int?) ?? 0;
  //     offsetSample.add(raw);

  //     // sample 10 offset
  //     if (offsetSample.length > 10) offsetSample.removeAt(0);

  //     final sorted = List<int>.from(offsetSample)..sort();
  //     serverTimeOffset = sorted[sorted.length ~/ 2]; //ambil median

  //     print("server offset: $serverTimeOffset");
  //   });
  // }

  // NTP-style multi-sample calibration
  // 10x round-trip ke RTDB, ambil 3 dengan RTT terendah, rata-rata offset
  Future<void> calibrate({bool isRetry = false}) async {
    final samples = <({int offset, int rtt})>[];

    for (int i = 0; i < 10; i++) {
      final t1 = DateTime.now().millisecondsSinceEpoch;
      final pingRef = rtdb.child('_ping').push();
      await pingRef.set(ServerValue.timestamp);
      final snapshot = await pingRef.get();
      final t3 = DateTime.now().millisecondsSinceEpoch;
      final serverTime = snapshot.value as int;

      final rtt = t3 - t1;
      final offset = serverTime - t1 - (rtt ~/ 2);
      samples.add((offset: offset, rtt: rtt));

      await pingRef.remove();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    samples.sort((a, b) => a.rtt.compareTo(b.rtt));

    final best = samples.take(3).toList();
    serverTimeOffset =
        best.map((s) => s.offset).reduce((a, b) => a + b) ~/ best.length;

    // RTT quality gate
    final avgRtt = best.map((s) => s.rtt).reduce((a, b) => a + b) / 3;
    if (avgRtt > 400) {
      print(
        "WARNING: Poor network quality, avg RTT: ${avgRtt.toStringAsFixed(0)}ms",
      );
    }

    print("NTP calibrated offset: $serverTimeOffset");
    print(
      "RTT samples: ${samples.map((s) => '${s.rtt}ms(${s.offset})').join(', ')}",
    );

    // verification round (skip on retry to avoid infinite loop)
    if (!isRetry) {
      final t1 = DateTime.now().millisecondsSinceEpoch;
      final verifyRef = rtdb.child('_ping').push();
      await verifyRef.set(ServerValue.timestamp);
      final snap = await verifyRef.get();
      final t3 = DateTime.now().millisecondsSinceEpoch;
      final serverTime = snap.value as int;
      await verifyRef.remove();

      final verifyRtt = t3 - t1;
      final verifyOffset = serverTime - t1 - (verifyRtt ~/ 2);
      final diff = (verifyOffset - serverTimeOffset).abs();

      if (diff > 20 && verifyRtt < 200) {
        print("Calibration drift detected: ${diff}ms, recalibrating...");
        await calibrate(isRetry: true);
      }
    }
  }

  // Quick re-calibration: 3 samples, fine-tune (weighted blend, BUKAN overwrite)
  Future<void> calibrateQuick() async {
    final samples = <({int offset, int rtt})>[];

    for (int i = 0; i < 3; i++) {
      final t1 = DateTime.now().millisecondsSinceEpoch;
      final pingRef = rtdb.child('_ping').push();
      await pingRef.set(ServerValue.timestamp);
      final snapshot = await pingRef.get();
      final t3 = DateTime.now().millisecondsSinceEpoch;
      final serverTime = snapshot.value as int;

      final rtt = t3 - t1;
      final offset = serverTime - t1 - (rtt ~/ 2);
      samples.add((offset: offset, rtt: rtt));

      await pingRef.remove();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    samples.sort((a, b) => a.rtt.compareTo(b.rtt));

    final best = samples.take(2).toList();
    final quickOffset =
        best.map((s) => s.offset).reduce((a, b) => a + b) ~/ best.length;
    final bestRtt =
        best.map((s) => s.rtt).reduce((a, b) => a + b) / best.length;
    final diff = (quickOffset - serverTimeOffset).abs();

    // hanya update jika drift signifikan DAN RTT cukup bagus
    if (diff > 10 && bestRtt < 200) {
      // weighted blend: 70% existing (robust), 30% quick
      serverTimeOffset = ((serverTimeOffset * 0.7) + (quickOffset * 0.3))
          .round();
      print(
        "NTP quick-calibrated (blended): $serverTimeOffset (quickOffset=$quickOffset, diff=$diff, avgRtt=${bestRtt.toStringAsFixed(0)})",
      );
    } else {
      print(
        "NTP quick-calibrate skipped: diff=${diff}ms, avgRtt=${bestRtt.toStringAsFixed(0)}ms (keeping existing: $serverTimeOffset)",
      );
    }
  }

  int getEstimatedServerTime() {
    return DateTime.now().millisecondsSinceEpoch + serverTimeOffset;
  }

  void dispose() {
    subOffset?.cancel();
    subOffset = null;
  }
}

final pocResyncServiceProvider = Provider<PocResyncService>((ref) {
  final syncRef = ref.read(pocSyncServiceProvider);
  final service = PocResyncService(syncRef);
  ref.onDispose(() => service.dispose());
  return service;
});

class PocResyncService {
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
  final PocSyncService syncService;
  Timer? resyncTimer;
  StreamSubscription? streamSub;

  PocResyncService(this.syncService);

  void startBroadcast(String roomID, int serverTime) {
    resyncTimer = Timer.periodic(Duration(milliseconds: 1500), (timer) {
      final now = syncService.getEstimatedServerTime();
      final position = now - serverTime;

      rtdb.child('playback_sessions/$roomID/leaderPosition').set({
        'positionMs': position,
        'broadcastTime': now,
      });
    });
  }

  void stopBroadcast(String roomID) {
    resyncTimer?.cancel();
  }

  void listenToLeaderPosition(String roomID, Function callback) {
    streamSub?.cancel();

    // subscribe ke stream posisi leader
    streamSub = rtdb
        .child('playback_sessions/$roomID/leaderPosition')
        .onValue
        .listen((event) {
          if (!event.snapshot.exists) return;

          final data = event.snapshot.value as Map<dynamic, dynamic>;
          final position = data['positionMs'] as int;
          final broadcastTime = data['broadcastTime'] as int;

          callback(position, broadcastTime);
        });
  }

  void stopListening() {
    streamSub?.cancel();
    streamSub = null;
  }

  // One-time broadcast: leader sends position once after delay
  void broadcastOnce(String roomID, int serverStartTime, {int delayMs = 2000}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      final now = syncService.getEstimatedServerTime();
      final position = now - serverStartTime;

      rtdb.child('playback_sessions/$roomID/startupCorrection').set({
        'positionMs': position,
        'broadcastTime': now,
      });

      print("One-time broadcast: position=$position, time=$now");
    });
  }

  // One-time listen: follower receives correction once then stops
  void listenOnce(
    String roomID,
    Function(int position, int broadcastTime) callback,
  ) {
    StreamSubscription? sub;
    bool hasReceived = false;

    sub = rtdb
        .child('playback_sessions/$roomID/startupCorrection')
        .onValue
        .listen((event) {
          if (!event.snapshot.exists) return;
          // skip stale data — only process once
          if (hasReceived) return;
          hasReceived = true;

          final data = event.snapshot.value as Map<dynamic, dynamic>;
          final position = data['positionMs'] as int;
          final broadcastTime = data['broadcastTime'] as int;

          callback(position, broadcastTime);

          // auto-stop after receiving
          sub?.cancel();
        });

    // timeout: cancel after 3s if nothing received
    Future.delayed(const Duration(seconds: 3), () {
      if (!hasReceived) {
        sub?.cancel();
        print("One-time listen timed out, continuing without correction");
      }
    });
  }

  void dispose() {
    resyncTimer?.cancel();
    resyncTimer = null;
    stopListening();
  }
}

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

  void initService() {
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
    resyncTimer = Timer.periodic(Duration(seconds: 3), (timer) {
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

  void dispose() {
    resyncTimer?.cancel();
    resyncTimer = null;
    stopListening();
  }
}

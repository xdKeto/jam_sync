import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pocSyncServiceProvider = Provider<PocSyncService>((ref) {
  final service = PocSyncService();
  service.initService();
  return service;
});

class PocSyncService {
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
  final List<int> offsetSample = [];
  int serverTimeOffset = 0;

  // void initService() {
  //   rtdb.child('.info/serverTimeOffset').onValue.listen((event) {
  //     serverTimeOffset = (event.snapshot.value as int?) ?? 0;
  //     print("server offset: $serverTimeOffset");
  //   });
  // }
  void initService() {
    rtdb.child('.info/serverTimeOffset').onValue.listen((event) {
      final raw = (event.snapshot.value as int?) ?? 0;
      offsetSample.add(raw);

      // sample 10 offset
      if (offsetSample.length > 10) offsetSample.removeAt(0);

      final sorted = List<int>.from(offsetSample)..sort();
      serverTimeOffset = sorted[sorted.length ~/ 2]; //ambil median

      print("server offset: $serverTimeOffset");
    });
  }

  int getEstimatedServerTime() {
    return DateTime.now().millisecondsSinceEpoch + serverTimeOffset;
  }
}

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pocSyncServiceProvider = Provider<PocSyncService>((ref) {
  final service = PocSyncService();
  service.initService();
  return service;
});

class PocSyncService {
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
int serverTimeOffset = 0;

  void initService() {
    rtdb.child('.info/serverTimeOffset').onValue.listen((event) {
      serverTimeOffset = (event.snapshot.value as int?) ?? 0;
      print("server offset: $serverTimeOffset");
    });
  }

  int getEstimatedServerTime() {
    return DateTime.now().millisecondsSinceEpoch + serverTimeOffset;
  }
}

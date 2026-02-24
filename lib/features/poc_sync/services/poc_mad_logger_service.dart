import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/poc_sync/services/sync_provider.dart';
import 'package:uuid/uuid.dart';

// Leader creates session and stores in RTDB agar semua client pakai session yang sama
Future<String> createSharedLogSession(String roomId) async {
  final rtdb = FirebaseDatabase.instance.ref();
  final doc = await FirebaseFirestore.instance.collection('poc_sessions').add({
    'roomID': roomId,
    'startedAt': FieldValue.serverTimestamp(),
  });

  // simpan sessionId di RTDB supaya member bisa baca
  await rtdb.child('playback_sessions/$roomId/logSessionId').set(doc.id);

  return doc.id;
}

// Member reads existing session from RTDB
Future<String?> getSharedLogSession(String roomId) async {
  final rtdb = FirebaseDatabase.instance.ref();
  final snapshot = await rtdb
      .child('playback_sessions/$roomId/logSessionId')
      .get();

  if (snapshot.exists) {
    return snapshot.value as String;
  }
  return null;
}

class PocMadLoggerService {
  Timer? logTimer;
  String? sessionId;
  final String clientID = const Uuid().v4();
  final Ref ref;

  PocMadLoggerService(this.ref);

  void startLog(String session, int serverStartTime) {
    logTimer?.cancel();
    final syncService = ref.read(pocSyncServiceProvider);

    sessionId = session;

    logTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final positionMs = syncService.getEstimatedServerTime() - serverStartTime;
      final index = (positionMs / 545.45).floor();

      // deterministic sequence number untuk pair antar client
      final logSequence = (positionMs / 500).floor();

      // raw offset terakhir untuk debugging
      final rawOffset = syncService.serverTimeOffset;

      FirebaseFirestore.instance
          .collection('poc_sessions')
          .doc(sessionId)
          .collection('logs')
          .add({
            'client': clientID,
            'localTime': now,
            'currentIndex': index,
            'currentPosition': positionMs,
            'logSequence': logSequence,
            'timestamp': FieldValue.serverTimestamp(),
            'serverTimeOffset': syncService.serverTimeOffset,
            'rawOffset': rawOffset,
          });
    });
  }

  void stopLog() {
    logTimer?.cancel();

    if (sessionId != null) {
      FirebaseFirestore.instance
          .collection('poc_sessions')
          .doc(sessionId)
          .update({'endAt': FieldValue.serverTimestamp()});
    }
  }
}

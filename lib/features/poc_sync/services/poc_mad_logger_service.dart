import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/poc_sync/services/sync_provider.dart';
import 'package:uuid/uuid.dart';

Future<String> createLogSession(String roomID) async {
  final doc = await FirebaseFirestore.instance.collection('poc_sessions').add({
    'roomID': roomID,
    'startedAt': FieldValue.serverTimestamp(),
  });

  return doc.id;
}

class PocMadLoggerService {
  Timer? logTimer;
  String? sessionId;
  final String clientID = Uuid().v4();
  final Ref ref;

  PocMadLoggerService(this.ref);

  void startLog(String session, int serverStartTime) {
    final syncService = ref.read(pocSyncServiceProvider);

    sessionId = session;

    logTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      // if (!state.isPlaying) return;

      final positionMs = syncService.getEstimatedServerTime() - serverStartTime;
      final index = (positionMs / 545.45).floor();

      FirebaseFirestore.instance
          .collection('poc_sessions')
          .doc(sessionId)
          .collection('logs')
          .add({
            'client': clientID,
            'localTime': DateTime.now().millisecondsSinceEpoch,
            'currentIndex': index,
            'currentPosition': positionMs,
            'timestamp': FieldValue.serverTimestamp(),
            'serverTimeOffset': syncService.serverTimeOffset,
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

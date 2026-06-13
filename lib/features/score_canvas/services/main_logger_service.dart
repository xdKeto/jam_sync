import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:jam_sync/features/score_canvas/services/sync_service.dart';
import 'package:uuid/uuid.dart';

Future<String> createMainLogSession(String roomID) async {
  final doc = await FirebaseFirestore.instance.collection('main_sessions').add({
    'roomID': roomID,
    'startedAt': FieldValue.serverTimestamp(),
  });

  await FirebaseDatabase.instance
      .ref()
      .child('playback_sessions/$roomID/logSessionId')
      .set(doc.id);

  return doc.id;
}

Future<String?> getMainLogSession(String roomID) async {
  final snapshot = await FirebaseDatabase.instance
      .ref()
      .child('playback_sessions/$roomID/logSessionId')
      .get();

  if (snapshot.exists) {
    return snapshot.value as String;
  }
  return null;
}

class MainLoggerService {
  Timer? logTimer;
  String? sessionId;
  final String _clientID = const Uuid().v4();
  int lastLogSequence = -1;
  final SyncService syncService;

  String get clientID => _clientID;
  
  MainLoggerService({required this.syncService});

  void startLog(String session, int serverStartTime, double tempo) {
    logTimer?.cancel();
    sessionId = session;
    lastLogSequence = -1;

    logTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final positionMs = syncService.getEstimatedServerTime() - serverStartTime;
      final beatDurationMs = 60000 / tempo;
      final index = (positionMs / beatDurationMs).floor();

      final logSequence = (positionMs / 500).floor();

      if (logSequence == lastLogSequence) return;
      lastLogSequence = logSequence;

      FirebaseFirestore.instance
          .collection('main_sessions')
          .doc(sessionId)
          .collection('logs')
          .add({
        'client': _clientID,
        'localTime': now,
        'currentIndex': index,
        'currentPosition': positionMs,
        'logSequence': logSequence,
        'timestamp': FieldValue.serverTimestamp(),
        'serverTimeOffset': serverTimeOffset,
        'rawOffset': rawOffset,
      });
    });
  }

  void stopLog() {
    logTimer?.cancel();

    if (sessionId != null) {
      FirebaseFirestore.instance
          .collection('main_sessions')
          .doc(sessionId)
          .update({'endAt': FieldValue.serverTimestamp()});
    }
  }

  int serverTimeOffset = 0;
  int rawOffset = 0;

  void updateOffset(int offset, int raw) {
    serverTimeOffset = offset;
    rawOffset = raw;
  }

  void dispose() {
    logTimer?.cancel();
    stopLog();
  }
}
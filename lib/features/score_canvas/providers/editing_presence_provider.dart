import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// set up presence
final editingPresenceProvider =
    StreamProvider.family<Map<String, ({String barPath, int beatIndex})>, String>((ref, projectId) {
      final rtdb = FirebaseDatabase.instance.ref();

      return rtdb.child('playback_sessions/$projectId/editing').onValue.map((event) {
        if (!event.snapshot.exists) return <String, ({String barPath, int beatIndex})>{};
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        return data.map((uid, val) {
          final d = val as Map<dynamic, dynamic>;
          final barPath = d['barPath'] as String;
          final beatIndex = (d['beatIndex'] as int?) ?? -1;
          return MapEntry(uid as String, (barPath: barPath, beatIndex: beatIndex));
        });
      });
    });

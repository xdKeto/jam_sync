import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final editingPresenceProvider = StreamProvider.family<Map<String, String>, String>((ref, projectId) {
  final rtdb = FirebaseDatabase.instance.ref();
  return rtdb
      .child('playback_sessions/$projectId/editing')
      .onValue
      .map((event) {
    if (!event.snapshot.exists) return <String, String>{};
    final data = event.snapshot.value as Map<dynamic, dynamic>;
    return data.map((uid, val) {
      final d = val as Map<dynamic, dynamic>;
      return MapEntry(uid as String, d['barPath'] as String);
    });
  });
});

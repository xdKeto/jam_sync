import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/room_provider.dart';
import 'package:jam_sync/shared/models/participant_info_model.dart';

final participantsStreamProvider = StreamProvider.family<List<ParticipantInfo>, String>((
  ref,
  projectID,
) {
  final rtdb = FirebaseDatabase.instance.ref();
  final firestore = FirebaseFirestore.instance;

  return rtdb.child('playback_sessions/$projectID/participants').onValue.asyncMap((event) async {
    if (!event.snapshot.exists) return <ParticipantInfo>[];

    final data = event.snapshot.value as Map<dynamic, dynamic>;
    final leaderID = ref.read(roomProvider).leaderID;

    final futures = data.entries.map((e) async {
      final uid = e.key as String;
      final participantData = e.value as Map<dynamic, dynamic>;

      final doc = await firestore.collection('users').doc(uid).get();
      final userData = doc.data();

      return ParticipantInfo(
        uid: uid,
        displayName: userData?['displayName'] ?? 'Unknown',
        photoURL: userData?['photoURL'],
        isOnline: participantData['isOnline'] == true,
        isLeader: uid == leaderID,
        latencyMs: participantData['latencyMs'] as int? ?? 0,
        isReady: participantData['isReady'] == true,
      );
    });

    return Future.wait(futures.toList());
  });
});

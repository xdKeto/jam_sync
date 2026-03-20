import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>(
  (ref) => RoomNotifier(ref),
);

class RoomState {
  final String? roomID;
  final String? roomCode;
  final String? leaderID;
  final int serverStartTime;
  final List<String> participants;
  final bool isPlaying;
  final bool isLeader;
  final bool isLoading;

  const RoomState({
    this.roomID,
    this.roomCode,
    this.leaderID,
    this.serverStartTime = 0,
    this.participants = const [],
    this.isPlaying = false,
    this.isLeader = false,
    this.isLoading = false,
  });

  RoomState copyWith({
    String? roomID,
    String? roomCode,
    String? leaderID,
    int? serverStartTime,
    List<String>? participants,
    bool? isPlaying,
    bool? isLeader,
    bool? isLoading,
  }) {
    return RoomState(
      roomID: roomID ?? this.roomID,
      roomCode: roomCode ?? this.roomCode,
      leaderID: leaderID ?? this.leaderID,
      serverStartTime: serverStartTime ?? this.serverStartTime,
      participants: participants ?? this.participants,
      isPlaying: isPlaying ?? this.isPlaying,
      isLeader: isLeader ?? this.isLeader,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RoomNotifier extends StateNotifier<RoomState> {
  final Ref ref;
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
  StreamSubscription? roomSubscription;

  RoomNotifier(this.ref) : super(const RoomState());

  void listenToRoom(String roomID) {
    roomSubscription?.cancel();

    roomSubscription = rtdb.child('playback_sessions/$roomID').onValue.listen((
      event,
    ) {
      if (!event.snapshot.exists) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>;

      state = state.copyWith(
        isPlaying: data['isPlaying'] as bool,
        serverStartTime: data['serverStartTime'] as int,
        leaderID: data['leaderId'] as String,
      );
    });
  }

  void stopListen() {
    roomSubscription?.cancel();
    roomSubscription = null;
  }

  @override
  void dispose() {
    stopListen();
    super.dispose();
  }

  Future<void> createAndJoinRoom({
    required String projectID,
    required String roomCode,
    required String userID,
  }) async {
    stopListen();
    state = state.copyWith(isLoading: true);

    try {
      await rtdb.child('rooms/$roomCode').set({'roomId': projectID});

      await rtdb.child('playback_sessions/$projectID').set({
        'roomCode': roomCode,
        'leaderId': userID,
        'isPlaying': false,
        'serverStartTime': 0,
        'createdAt': ServerValue.timestamp,
      });

      await rtdb
          .child('playback_sessions/$projectID/participants/$userID')
          .set(true);

      state = state.copyWith(
        isLoading: false,
        isLeader: true,
        roomID: projectID,
        roomCode: roomCode,
        leaderID: userID,
      );

      listenToRoom(projectID);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception("createAndJoinRoom error: $e");
    }
  }

  Future<void> joinExistingRoom({
    required String roomCode,
    required String userID,
  }) async {
    stopListen();
    state = state.copyWith(isLoading: true);

    try {
      final roomRef = await rtdb.child('rooms/$roomCode').get();
      if (!roomRef.exists) throw Exception('RTDB room not found');

      final roomData = roomRef.value as Map<dynamic, dynamic>;
      final roomID = roomData['roomId'] as String;

      await rtdb
          .child('playback_sessions/$roomID/participants/$userID')
          .set(true);

      final sessionRef = await rtdb.child('playback_sessions/$roomID').get();
      final sessionData = sessionRef.value as Map<dynamic, dynamic>;
      final leaderID = sessionData['leaderId'] as String;

      state = state.copyWith(
        isLoading: false,
        isLeader: userID == leaderID,
        roomID: roomID,
        roomCode: roomCode,
        leaderID: leaderID,
      );

      listenToRoom(roomID);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception("joinExistingRoom error: $e");
    }
  }
}
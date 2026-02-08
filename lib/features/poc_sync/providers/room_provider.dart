import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

String generateRoomCode() {
  final random = Random();
  return List.generate(6, (_) => random.nextInt(10)).join();
}

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>(
  (ref) => RoomNotifier(ref),
);

class RoomState {
  final String? roomId;
  final String? roomCode;
  final String? leaderId;
  final bool isPlaying;
  final int serverStartTime;
  final List<String> participants;
  final bool isLeader;
  final bool isLoading;

  const RoomState({
    this.roomId,
    this.roomCode,
    this.leaderId,
    this.isPlaying = false,
    this.serverStartTime = 0,
    this.participants = const [],
    this.isLeader = false,
    this.isLoading = false,
  });

  RoomState copyWith({
    String? roomId,
    String? roomCode,
    String? leaderId,
    bool? isPlaying,
    int? serverStartTime,
    List<String>? participants,
    bool? isLeader,
    bool? isLoading,
  }) {
    return RoomState(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      leaderId: leaderId ?? this.leaderId,
      isPlaying: isPlaying ?? this.isPlaying,
      serverStartTime: serverStartTime ?? this.serverStartTime,
      participants: participants ?? this.participants,
      isLeader: isLeader ?? this.isLeader,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RoomNotifier extends StateNotifier<RoomState> {
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
  final Ref ref;

  RoomNotifier(this.ref) : super(RoomState());

  StreamSubscription? roomSubscription;

  void listenToRoom(String roomId) {
    roomSubscription?.cancel();

    roomSubscription = rtdb.child('playback_sessions/$roomId').onValue.listen((
      event,
    ) {
      if (!event.snapshot.exists) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>;

      state = state.copyWith(
        isPlaying: data['isPlaying'] as bool,
        serverStartTime: data['serverStartTime'] as int,
        leaderId: data['leaderId'] as String,
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

  Future<void> createRoom() async {
    // cancel existing listener
    stopListen();

    // update state jadi loading dulu ges
    state = state.copyWith(isLoading: true);

    try {
      String code = generateRoomCode();
      final roomId = const Uuid().v4();
      final userId = ref
          .read(authNotifierProvider.notifier)
          .getCurrentUser()!
          .uid;

      // generate room code
      print("generating code");
      bool codeExists = true;
      while (codeExists) {
        code = generateRoomCode();
        final snapshot = await rtdb.child('rooms/$code').get();
        codeExists = snapshot.exists;
      }

      print("write room");
      // write roomid
      await rtdb.child('rooms/$code').set({'roomId': roomId});

      print("write session");
      // write session
      await rtdb.child('playback_sessions/$roomId').set({
        'roomCode': code,
        'leaderId': userId,
        'isPlaying': false,
        'serverStartTime': 0,
        'createdAt': ServerValue.timestamp,
      });

      print("write self");
      // daftarin diri ke participants
      await rtdb
          .child('playback_sessions/$roomId/participants/$userId')
          .set(true);

      print("update state");
      // update state
      state = state.copyWith(
        isLoading: false,
        isLeader: true,
        roomId: roomId,
        roomCode: code,
        leaderId: userId,
      );

      print("listen");
      listenToRoom(roomId);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception("create room error: $e");
    }
  }

  Future<void> joinRoom(String roomCode) async {
    state = state.copyWith(isLoading: true);

    try {
      final userId = ref
          .read(authNotifierProvider.notifier)
          .getCurrentUser()!
          .uid;
      final roomRef = await rtdb.child('rooms/$roomCode').get();

      // cek room
      if (!roomRef.exists) throw Exception('Room not found');

      final roomData = roomRef.value as Map<dynamic, dynamic>;
      final roomId = roomData['roomId'] as String;

      // daftarin diri
      await rtdb
          .child('playback_sessions/$roomId/participants/$userId')
          .set(true);

      final sessionRef = await rtdb.child('playback_sessions/$roomId').get();
      final sessionData = sessionRef.value as Map<dynamic, dynamic>;
      final leaderId = sessionData['leaderId'] as String;

      bool isLeader = false;

      if (userId == leaderId) {
        isLeader = true;
      }

      // update state
      state = state.copyWith(
        isLoading: false,
        isLeader: isLeader,
        roomId: roomId,
        roomCode: roomCode,
        leaderId: leaderId,
      );
      listenToRoom(roomId);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception(e);
    }
  }

  
}

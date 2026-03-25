import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) => RoomNotifier(ref));

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
  Timer? latencyTimer;

  // Toggle: set true untuk testing latency, false untuk hemat RTDB
  static const bool kEnableLatencyProbe = true;

  String? probeProjectID;
  String? probeUserID;

  RoomNotifier(this.ref) : super(const RoomState());

  void listenToRoom(String roomID) {
    roomSubscription?.cancel();

    roomSubscription = rtdb.child('playback_sessions/$roomID').onValue.listen((event) {
      if (!event.snapshot.exists) {
        stopListen();
        return;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;

      final isPlaying = data['isPlaying'];
      final serverStartTime = data['serverStartTime'];
      final leaderID = data['leaderId'];
      if (isPlaying == null || serverStartTime == null || leaderID == null) return;

      state = state.copyWith(
        isPlaying: isPlaying as bool,
        serverStartTime: serverStartTime as int,
        leaderID: leaderID as String,
      );
    });
  }

  void stopListen() {
    roomSubscription?.cancel();
    roomSubscription = null;
    latencyTimer?.cancel();
    latencyTimer = null;

    if (probeProjectID != null && probeUserID != null) {
      // hapus data latency supaya appear offline
      rtdb.child('playback_sessions/$probeProjectID/participants/$probeUserID').update({
        'isOnline': false,
        'latencyMs': 0,
      });

      rtdb
          .child('playback_sessions/$probeProjectID/participants/$probeUserID/latencyProbe')
          .remove();
    }
    probeProjectID = null;
    probeUserID = null;
  }

  void leaveRoom() {
    stopListen();
    state = const RoomState();
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

      final participantRef = rtdb.child('playback_sessions/$projectID/participants/$userID');
      await participantRef.update({'isOnline': true, 'latencyMs': 0, 'isReady': false});

      await participantRef.onDisconnect().cancel();
      await participantRef.onDisconnect().update({'isOnline': false});

      state = state.copyWith(
        isLoading: false,
        isLeader: true,
        roomID: projectID,
        roomCode: roomCode,
        leaderID: userID,
      );

      listenToRoom(projectID);
      startLatencyProbe(projectID, userID);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception("createAndJoinRoom error: $e");
    }
  }

  Future<void> joinExistingRoom({required String roomCode, required String userID}) async {
    stopListen();
    state = state.copyWith(isLoading: true);

    try {
      final roomRef = await rtdb.child('rooms/$roomCode').get();
      if (!roomRef.exists) throw Exception('RTDB room not found');

      final roomData = roomRef.value as Map<dynamic, dynamic>;
      final roomID = roomData['roomId'] as String;

      final participantRef = rtdb.child('playback_sessions/$roomID/participants/$userID');
      await participantRef.update({'isOnline': true, 'latencyMs': 0, 'isReady': false});

      await participantRef.onDisconnect().cancel();
      await participantRef.onDisconnect().update({'isOnline': false});

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
      startLatencyProbe(roomID, userID);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception("joinExistingRoom error: $e");
    }
  }

  Future<int> measureRTT(String probePath) async {
    final tSend = DateTime.now().millisecondsSinceEpoch;
    await rtdb.child(probePath).set(ServerValue.timestamp);
    final tReceive = DateTime.now().millisecondsSinceEpoch;

    final rtt = tReceive - tSend;
    final oneWay = rtt ~/ 2;

    debugPrint('[LatencyProbe] tSend=$tSend tReceive=$tReceive rtt=$rtt oneWay=$oneWay');
    return oneWay;
  }

  void startLatencyProbe(String projectID, String userID) {
    latencyTimer?.cancel();

    if (!kEnableLatencyProbe) {
      debugPrint('[LatencyProbe] Disabled (kEnableLatencyProbe=false)');
      return;
    }

    probeProjectID = projectID;
    probeUserID = userID;

    final probePath = 'playback_sessions/$projectID/participants/$userID/latencyProbe';
    final latencyPath = 'playback_sessions/$projectID/participants/$userID/latencyMs';

    debugPrint('[LatencyProbe] Starting probe for project=$projectID user=$userID');

    measureRTT(probePath)
        .then((latency) {
          debugPrint('[LatencyProbe] Initial latency=$latency ms');
          return rtdb.child(latencyPath).set(latency);
        })
        .catchError((e) {
          debugPrint('[LatencyProbe] ERROR: $e');
        });

    latencyTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      try {
        final latency = await measureRTT(probePath);
        await rtdb.child(latencyPath).set(latency);
        debugPrint('[LatencyProbe] Periodic write: $latency ms');
      } catch (e) {
        debugPrint('[LatencyProbe] Periodic ERROR: $e');
      }
    });
  }
}

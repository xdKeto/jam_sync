import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/features/score_canvas/services/sync_service.dart';

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>((ref) => RoomNotifier(ref));

class RoomState {
  final String? roomID;
  final String? roomCode;
  final String? leaderID;
  final int serverStartTime;
  final List<String> participants;
  final bool isLeader;
  final bool isLoading;
  final int countdownBeats;
  final String? sessionId;

  bool get isPlaying => serverStartTime > 0;

  const RoomState({
    this.roomID,
    this.roomCode,
    this.leaderID,
    this.serverStartTime = 0,
    this.participants = const [],
    this.isLeader = false,
    this.isLoading = false,
    this.countdownBeats = 4,
    this.sessionId,
  });

  RoomState copyWith({
    String? roomID,
    String? roomCode,
    String? leaderID,
    int? serverStartTime,
    List<String>? participants,
    bool? isLeader,
    bool? isLoading,
    int? countdownBeats,
    String? sessionId,
  }) {
    return RoomState(
      roomID: roomID ?? this.roomID,
      roomCode: roomCode ?? this.roomCode,
      leaderID: leaderID ?? this.leaderID,
      serverStartTime: serverStartTime ?? this.serverStartTime,
      participants: participants ?? this.participants,
      isLeader: isLeader ?? this.isLeader,
      isLoading: isLoading ?? this.isLoading,
      countdownBeats: countdownBeats ?? this.countdownBeats,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class RoomNotifier extends StateNotifier<RoomState> {
  final Ref ref;
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
  StreamSubscription? roomSubscription;
  Timer? latencyTimer;
  
  // user ping checker
  static const bool latencyProbe = true;
  String? probeProjectID;
  String? probeUserID;

  RoomNotifier(this.ref) : super(const RoomState());

  // listener state room
  void listenToRoom(String roomID) {
    roomSubscription?.cancel();

    roomSubscription = rtdb.child('playback_sessions/$roomID').onValue.listen((event) { //subscribe, listen onvalue
      if (!event.snapshot.exists) {
        stopListen();
        return;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;

      final isPlaying = data['isPlaying'];
      final serverStartTime = data['serverStartTime'];
      final leaderID = data['leaderId'];
      final countdownBeats = data['countdownBeats'];
      final sessionId = data['sessionId'] as String?;

      // case kalo tengah playback crash, tpi node nya masih nyala di rtdb
      if (isPlaying == false && (serverStartTime as int? ?? 0) > 0) {
        rtdb.child('playback_sessions/$roomID').update({
          'serverStartTime': 0,
          'isPlaying': false,
        });
        state = state.copyWith(serverStartTime: 0);
        return;
      }

      if (isPlaying == null || serverStartTime == null || leaderID == null) return;

      state = state.copyWith(
        serverStartTime: serverStartTime as int,
        leaderID: leaderID as String,
        countdownBeats: countdownBeats as int? ?? 4,
        sessionId: sessionId,
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

      rtdb.child('playback_sessions/$probeProjectID/editing/$probeUserID').remove();

      rtdb
          .child('playback_sessions/$probeProjectID/participants/$probeUserID/latencyProbe')
          .remove();
    }
    probeProjectID = null;
    probeUserID = null;
  }

  void leaveRoom() {
    ref.read(syncServiceProvider).pauseBackgroundCalibration();
    stopListen();
    state = const RoomState();
  }

  @override
  void dispose() {
    stopListen();
    super.dispose();
  }

  // leader
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
      await participantRef.onDisconnect().update({'isOnline': false, 'isReady': false});
      
      // re-cleanup, misal ada sisa idk
      final editingRef = rtdb.child('playback_sessions/$projectID/editing/$userID');
      await editingRef.onDisconnect().cancel(); 
      await editingRef.onDisconnect().remove();

      state = state.copyWith(
        isLoading: false,
        isLeader: true,
        roomID: projectID,
        roomCode: roomCode,
        leaderID: userID,
      );

      listenToRoom(projectID);
      startLatencyProbe(projectID, userID); //ping check

      //start background calibration
      ref.read(syncServiceProvider).startBackgroundCalibration();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception("createAndJoinRoom error: $e");
    }
  }

  // member
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
      await participantRef.onDisconnect().update({'isOnline': false, 'isReady': false});

      final editingRef = rtdb.child('playback_sessions/$roomID/editing/$userID');
      await editingRef.onDisconnect().cancel();
      await editingRef.onDisconnect().remove();

      final sessionRef = await rtdb.child('playback_sessions/$roomID').get();
      final sessionData = sessionRef.value as Map<dynamic, dynamic>;
      final leaderID = sessionData['leaderId'] as String;
      final serverStartTime = sessionData['serverStartTime'] as int? ?? 0;
      final isPlaying = sessionData['isPlaying'] as bool? ?? false;

      // cek case bug session lama/expired, kalo ada reset semua
      if (!isPlaying && serverStartTime > 0) {
        await rtdb.child('playback_sessions/$roomID').update({
          'serverStartTime': 0,
          'isPlaying': false,
        });
      }

      state = state.copyWith(
        isLoading: false,
        isLeader: userID == leaderID,
        roomID: roomID,
        roomCode: roomCode,
        leaderID: leaderID,
      );

      listenToRoom(roomID);
      startLatencyProbe(roomID, userID); //ping check

      // start background calibration
      ref.read(syncServiceProvider).startBackgroundCalibration();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      throw Exception("joinExistingRoom error: $e");
    }
  }

  // ping checker
  Future<int> measureRTT(String probePath) async {
    final tSend = DateTime.now().millisecondsSinceEpoch;
    await rtdb.child(probePath).set(ServerValue.timestamp);
    final tReceive = DateTime.now().millisecondsSinceEpoch;

    final rtt = tReceive - tSend;
    final oneWay = rtt ~/ 2;

    return oneWay;
  }

  void startLatencyProbe(String projectID, String userID) async {
    latencyTimer?.cancel();

    if (!latencyProbe) {
      return;
    }

    probeProjectID = projectID;
    probeUserID = userID;

    final probePath = 'playback_sessions/$projectID/participants/$userID/latencyProbe';
    final latencyPath = 'playback_sessions/$projectID/participants/$userID/latencyMs';

    // delay 5 seconds, nunggu cold-start
    await Future.delayed(Duration(seconds: 5));

    measureRTT(probePath)
        .then((latency) {
          return rtdb.child(latencyPath).set(latency);
        })
        .catchError((e) {
          debugPrint('startLatencyPrboe ERROR: $e');
        });

    // ping check /15 detik
    latencyTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final latency = await measureRTT(probePath);
        await rtdb.child(latencyPath).set(latency);
      } catch (e) {
        debugPrint('startLatencyProbe timer ERROR: $e');
      }
    });
  }

  // debug function playback, reset semua state, variable, dll
  Future<void> forceResetPlaybackState() async {
    if (state.roomID == null) return;

    final roomID = state.roomID!;
    final Map<String, dynamic> updates = {};

    updates['playback_sessions/$roomID/serverStartTime'] = 0;
    updates['playback_sessions/$roomID/isPlaying'] = false;
    updates['playback_sessions/$roomID/sessionId'] = null;
    updates['playback_sessions/$roomID/playbackIntent'] = null;
    updates['playback_sessions/$roomID/viewers'] = null;

    // smua isReady = false
    final participantsRef = FirebaseDatabase.instance.ref()
        .child('playback_sessions/$roomID/participants');
    final snapshot = await participantsRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      for (final key in data.keys) {
        updates['playback_sessions/$roomID/participants/$key/isReady'] = false;
      }
    }

    await FirebaseDatabase.instance.ref().update(updates);
    state = state.copyWith(serverStartTime: 0, sessionId: null);
  }

  // debug function editing, rebuild partitur
  Future<void> forceResetAndRebuildSections() async {
    if (state.roomID == null) return;

    final roomID = state.roomID!;

    await rtdb.child('playback_sessions/$roomID').update({
      'sectionsNeedRebuild': ServerValue.timestamp,
    });
 
    await forceResetPlaybackState();

    // trigger stream partitur
    try {
      ref.invalidate(sectionsStreamProvider((projectID: roomID, canvasID: state.roomCode ?? '')));
    } catch (e) {
      debugPrint('RoomNotifier invalidate eror: $e');
    }
  }

  
}

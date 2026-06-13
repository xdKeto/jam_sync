import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jam_sync/shared/models/bar_model.dart';
import 'package:jam_sync/shared/models/section_model.dart';

enum IntentState { idle, waiting, allReady }

class PlaybackIntentState { 
  final IntentState state;
  final bool isIntentSent;
  final int totalOnline;
  final int readyCount;
  final List<String> notReadyNames;
  final String? intentSentBy;
  final String leaderId;
  final bool isMyReady;
  final int timestamp;
  final String? selectedCanvasId;
  final String? selectedCanvasTitle;

  const PlaybackIntentState({
    this.state = IntentState.idle,
    this.isIntentSent = false,
    this.totalOnline = 0,
    this.readyCount = 0,
    this.notReadyNames = const [],
    this.intentSentBy,
    this.leaderId = '',
    this.isMyReady = false,
    this.timestamp = 0,
    this.selectedCanvasId,
    this.selectedCanvasTitle,
  });

  PlaybackIntentState copyWith({
    IntentState? state,
    bool? isIntentSent,
    int? totalOnline,
    int? readyCount,
    List<String>? notReadyNames,
    String? intentSentBy,
    String? leaderId,
    bool? isMyReady,
    int? timestamp,
    String? selectedCanvasId,
    String? selectedCanvasTitle,
  }) {
    return PlaybackIntentState(
      state: state ?? this.state,
      isIntentSent: isIntentSent ?? this.isIntentSent,
      totalOnline: totalOnline ?? this.totalOnline,
      readyCount: readyCount ?? this.readyCount,
      notReadyNames: notReadyNames ?? this.notReadyNames,
      intentSentBy: intentSentBy ?? this.intentSentBy,
      leaderId: leaderId ?? this.leaderId,
      isMyReady: isMyReady ?? this.isMyReady,
      timestamp: timestamp ?? this.timestamp,
      selectedCanvasId: selectedCanvasId ?? this.selectedCanvasId,
      selectedCanvasTitle: selectedCanvasTitle ?? this.selectedCanvasTitle,
    );
  }
}

class PlaybackIntentController extends StateNotifier<PlaybackIntentState> {
  final String roomID;
  final String projectID;
  final String defaultCanvasID;
  final String roomCode;
  final String userID;
  final bool isLeader;
  final String userName;
  final double tempo;
  final String timeSignature;
  final int countdownBeats;
  final List<SectionModel> sections;
  // final Future<List<BarModel>> Function(String sectionID)? getBarsForSection;

  String tempSelectedCanvasID = '';
  String tempSelectedCanvasTitle = '';

  StreamSubscription? intentSubscription;
  StreamSubscription? participantsSubscription;
  Timer? timeoutTimer;

  PlaybackIntentController({
    required this.roomID,
    required this.projectID,
    required this.defaultCanvasID,
    required this.roomCode,
    required this.userID,
    required this.isLeader,
    required this.userName,
    required this.tempo,
    required this.timeSignature,
    required this.countdownBeats,
    required this.sections,
    // this.getBarsForSection,
  }) : super(const PlaybackIntentState()) {
    tempSelectedCanvasID = defaultCanvasID;
    initListeners();
  }

  void initListeners() {
    listenIntent();
    listenParticipants();
  }

  void setSelectedCanvas(String canvasId, String title) {
    tempSelectedCanvasID = canvasId;
    tempSelectedCanvasTitle = title;
    state = state.copyWith(
      selectedCanvasId: canvasId,
      selectedCanvasTitle: title,
    );
  }

  void initSelectedCanvas(String canvasId, String title) {
    if (tempSelectedCanvasID.isEmpty) {
      tempSelectedCanvasID = canvasId;
      tempSelectedCanvasTitle = title;
      state = state.copyWith(
        selectedCanvasId: canvasId,
        selectedCanvasTitle: title,
      );
    }
  }

  String get selectedCanvasId => tempSelectedCanvasID;
  String get selectedCanvasTitle => tempSelectedCanvasTitle;

  void listenIntent() { //updat state idle/waiting/partitur
    intentSubscription?.cancel();
    intentSubscription = FirebaseDatabase.instance
        .ref()
        .child('playback_sessions/$roomID/playbackIntent')
        .onValue
        .listen((event) {
          if (!event.snapshot.exists || event.snapshot.value == null) {
            // expired
            if (state.state != IntentState.idle) {
              state = state.copyWith(
                state: IntentState.idle,
                isIntentSent: false,
                intentSentBy: null,
                readyCount: 0,
                notReadyNames: [],
              );
            }
            return;
          }

          final data = event.snapshot.value as Map<dynamic, dynamic>;
          final isIntentSent = data['isIntentSent'] == true;
          final leaderId = data['leaderId'] as String? ?? '';
          final timestamp = data['timestamp'] as int? ?? 0;
          final selectedCanvasId = data['selectedCanvasId'] as String?;
          final selectedCanvasTitle = data['selectedCanvasTitle'] as String?;

          if (isIntentSent) {
            // leadeer waiting
            if (state.state == IntentState.idle && isLeader) {
              state = state.copyWith(
                state: IntentState.waiting,
                isIntentSent: true,
                intentSentBy: leaderId,
                leaderId: leaderId,
                timestamp: timestamp,
                selectedCanvasId: selectedCanvasId,
                selectedCanvasTitle: selectedCanvasTitle,
              );
            } else if (state.state == IntentState.idle && !isLeader) {
              // member terima intent leader
              state = state.copyWith(
                state: IntentState.waiting,
                isIntentSent: true,
                intentSentBy: leaderId,
                leaderId: leaderId,
                timestamp: timestamp,
                selectedCanvasId: selectedCanvasId,
                selectedCanvasTitle: selectedCanvasTitle,
              );
            } else if (!isLeader) {
              // update partitur
              state = state.copyWith(
                selectedCanvasId: selectedCanvasId,
                selectedCanvasTitle: selectedCanvasTitle,
              );
            } else if (isLeader) {
              state = state.copyWith(
                selectedCanvasId: selectedCanvasId,
                selectedCanvasTitle: selectedCanvasTitle,
              );
            }
          } else {
            // cancel
            if (state.state != IntentState.idle) {
              state = state.copyWith(
                state: IntentState.idle,
                isIntentSent: false,
                intentSentBy: null,
                readyCount: 0,
                notReadyNames: [],
              );
            }
          }
        });
  }

  void listenParticipants() { //listen ke status ready/online/offline member
    participantsSubscription?.cancel();
    participantsSubscription = FirebaseDatabase.instance
        .ref()
        .child('playback_sessions/$roomID/participants')
        .onValue
        .listen((event) {
          if (!event.snapshot.exists || event.snapshot.value == null) {
            state = state.copyWith(
              totalOnline: 0,
              readyCount: 0,
              notReadyNames: [],
              isMyReady: false,
            );
            updateReadyState(0, []);
            return;
          }

          final data = event.snapshot.value as Map<dynamic, dynamic>;
          int onlineCount = 0;
          int readyCount = 0;
          List<String> notReady = [];
          bool myReady = false;

          for (final entry in data.entries) {
            final participantData = entry.value as Map<dynamic, dynamic>;
            final isOnline = participantData['isOnline'] == true;
            final isReady = participantData['isReady'] == true;

            if (isOnline) {
              onlineCount++;
              if (isReady) {
                readyCount++;
              } else {
                final name =
                    participantData['displayName'] as String? ?? 'Unknown';
                if (name.isNotEmpty) notReady.add(name);
              }
            }

            if (entry.key == userID) {
              myReady = isReady;
            }
          }

          state = state.copyWith(
            totalOnline: onlineCount,
            readyCount: readyCount,
            notReadyNames: notReady,
            isMyReady: myReady,
          );

          updateReadyState(readyCount, notReady);
        });
  }

  void updateReadyState(int readyCount, List<String> notReady) { //detect ready
    if (isLeader && state.state == IntentState.waiting) {
      final allOnlineReady =
          readyCount >= state.totalOnline && state.totalOnline > 0;
      if (allOnlineReady && state.isMyReady) {
        state = state.copyWith(state: IntentState.allReady);
      }
    }
  }

  Future<void> sendIntent() async { //leader kirim intent
    if (!isLeader) return;
    if (state.isIntentSent) return;

    final Map<String, dynamic> updates = { //set data
      'playback_sessions/$roomID/playbackIntent': {
        'leaderId': userID,
        'isIntentSent': true,
        'timestamp': ServerValue.timestamp,
        'selectedCanvasId': tempSelectedCanvasID,
        'selectedCanvasTitle': tempSelectedCanvasTitle,
      },
    };

    final participantsRef = FirebaseDatabase.instance.ref().child(
      'playback_sessions/$roomID/participants',
    );

    final snapshot = await participantsRef.get(); // cek dupe
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      for (final entry in data.entries) {
        if (entry.key == userID) {
          updates['playback_sessions/$roomID/participants/${entry.key}/isReady'] =
              true;
        } else {
          updates['playback_sessions/$roomID/participants/${entry.key}/isReady'] =
              false;
        }
      }
    }

    // update state
    state = state.copyWith(
      state: IntentState.waiting,
      isIntentSent: true,
      intentSentBy: userID,
      leaderId: userID,
      readyCount: 1,
      notReadyNames: [],
      isMyReady: true,
    );

    // update rtdb
    await FirebaseDatabase.instance.ref().update(updates);

    timeoutTimer?.cancel();
    timeoutTimer = Timer(Duration(seconds: 60), () { //auto cancel kalo kelamaan
      if (state.state == IntentState.waiting) {
        cancelIntent();
      }
    });
  }

  Future<void> cancelIntent() async {
    if (!isLeader) return;

    final Map<String, dynamic> updates = {
      'playback_sessions/$roomID/playbackIntent': {'isIntentSent': false},
    };

    final participantsRef = FirebaseDatabase.instance.ref().child(
      'playback_sessions/$roomID/participants',
    );
    final snapshot = await participantsRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      for (final entry in data.entries) {
        updates['playback_sessions/$roomID/participants/${entry.key}/isReady'] =
            false;
      }
    }

    await FirebaseDatabase.instance.ref().update(updates);

    timeoutTimer?.cancel();
    state = state.copyWith(
      state: IntentState.idle,
      isIntentSent: false,
      intentSentBy: null,
      readyCount: 0,
      notReadyNames: [],
      isMyReady: false,
    );
  }

  Future<void> toggleReady() async {
    final participantsRef = FirebaseDatabase.instance.ref().child(
      'playback_sessions/$roomID/participants/$userID',
    );

    final snapshot = await participantsRef.get();
    final currentReady =
        (snapshot.value as Map<dynamic, dynamic>?)?['isReady'] == true;

    await participantsRef.update({
      'isReady': !currentReady,
      'displayName': userName,
    });
  }

  void resetIntent() {
    timeoutTimer?.cancel();

    FirebaseDatabase.instance
        .ref()
        .child('playback_sessions/$roomID/playbackIntent')
        .remove();

    state = const PlaybackIntentState();
  }

  @override
  void dispose() {
    intentSubscription?.cancel();
    participantsSubscription?.cancel();
    timeoutTimer?.cancel();
    super.dispose();
  }
}

class PlaybackIntentParams {
  final String roomID;
  final String projectID;
  final String defaultCanvasID;
  final String roomCode;
  final String userID;
  final bool isLeader;
  final String userName;
  final double tempo;
  final String timeSignature;
  final int countdownBeats;
  final List<SectionModel> sections;
  final Future<List<BarModel>> Function(String sectionID)? getBarsForSection;

  const PlaybackIntentParams({
    required this.roomID,
    required this.projectID,
    required this.defaultCanvasID,
    required this.roomCode,
    required this.userID,
    required this.isLeader,
    required this.userName,
    required this.tempo,
    required this.timeSignature,
    required this.countdownBeats,
    required this.sections,
    this.getBarsForSection,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaybackIntentParams &&
        other.roomID == roomID &&
        other.projectID == projectID &&
        other.defaultCanvasID == defaultCanvasID &&
        other.userID == userID;
  }

  @override
  int get hashCode => Object.hash(roomID, projectID, defaultCanvasID, userID);
}

final playbackIntentProvider =
    StateNotifierProvider.family<
      PlaybackIntentController,
      PlaybackIntentState,
      PlaybackIntentParams
    >((ref, params) {
      final userID = FirebaseAuth.instance.currentUser?.uid ?? '';
      final userName =
          FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown';

      return PlaybackIntentController(
        roomID: params.roomID,
        projectID: params.projectID,
        defaultCanvasID: params.defaultCanvasID,
        roomCode: params.roomCode,
        userID: userID.isEmpty ? params.userID : userID,
        isLeader: params.isLeader,
        userName: userName.isEmpty ? params.userName : userName,
        tempo: params.tempo,
        timeSignature: params.timeSignature,
        countdownBeats: params.countdownBeats,
        sections: params.sections,
        // getBarsForSection: params.getBarsForSection,
      );
    });

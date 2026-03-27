import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/poc_sync/providers/poc_playback_provider.dart';
import 'package:jam_sync/features/poc_sync/providers/poc_room_provider.dart';
import 'package:jam_sync/features/poc_sync/services/poc_sync_provider.dart';
import 'package:jam_sync/features/poc_sync/widgets/poc_box_grid_widget.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/the_button.dart';

class PocRoomScreen extends ConsumerStatefulWidget {
  const PocRoomScreen({super.key});

  @override
  ConsumerState<PocRoomScreen> createState() => _PocRoomScreenState();
}

class _PocRoomScreenState extends ConsumerState<PocRoomScreen> {
  final DatabaseReference rtdb = FirebaseDatabase.instance.ref();
  StreamSubscription? playbackSubscription;
  Timer? countdownTimer;
  int countdownSeconds = 0;
  bool isCounting = false;
  bool isSyncing = false;
  bool isStartPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupPlaybackListener();
      _preCalibrate();
    });
  }

  Future<void> _preCalibrate() async {
    if (!PocSyncService.useNtpCalibration) return;
    setState(() => isSyncing = true);
    await ref.read(pocSyncServiceProvider).calibrate();
    if (mounted) setState(() => isSyncing = false);
  }

  // listen pergantian status habis ditambah buffer
  void setupPlaybackListener() {
    final roomId = ref.read(pocRoomProvider).roomId;
    if (roomId == null) return;

    // listen serverStartTime
    playbackSubscription = rtdb
        .child('playback_sessions/$roomId/serverStartTime')
        .onValue
        .listen((event) {
          if (!event.snapshot.exists) return;

          final serverStartTime = (event.snapshot.value as int?) ?? 0;

          if (serverStartTime > 0 && !isCounting) {
            isCounting = true;
            startCountdown(serverStartTime);
          } else if (serverStartTime == 0) {
            isStartPressed = false;
          }
        });
  }

  void startCountdown(int serverStartTime) {
    countdownTimer?.cancel();

    // quick re-calibrate sebelum countdown (sudah pre-calibrate saat join)
    if (PocSyncService.useNtpCalibration) {
      setState(() => isSyncing = true);
      ref.read(pocSyncServiceProvider).calibrateQuick().then((_) {
        if (mounted) {
          setState(() => isSyncing = false);
          _runCountdown(serverStartTime);
        }
      });
    } else {
      _runCountdown(serverStartTime);
    }
  }

  void _runCountdown(int serverStartTime) {
    countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final now = ref.read(pocSyncServiceProvider).getEstimatedServerTime();
      final remaining = serverStartTime - now;

      if (remaining <= 0) {
        timer.cancel();
        setState(() {
          countdownSeconds = 0;
          isCounting = false;
        });
        // start autonomous playback
        final roomId = ref.read(pocRoomProvider).roomId!;
        ref
            .read(playbackControllerProvider.notifier)
            .startAutonomousPlayback(serverStartTime, roomId: roomId);
      } else {
        setState(() {
          countdownSeconds = (remaining / 1000).ceil();
        });
      }
    });
  }

  Future<void> onStartPressed() async {
    if (isStartPressed || isCounting || isSyncing) return;
    final roomId = ref.read(pocRoomProvider).roomId;
    if (roomId == null) return;

    setState(() => isStartPressed = true);
    await ref.read(playbackServiceProvider).startPlayback(roomId);
  }

  @override
  void dispose() {
    playbackSubscription?.cancel();
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(pocRoomProvider);
    final playbackState = ref.watch(playbackControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('POC Room')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                4.width,
                const Text(
                  'Connected!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            6.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Room Code:', style: TextStyle(fontSize: 12)),
                8.width,
                Text(
                  roomState.roomCode ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            12.height,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: roomState.isLeader ? Colors.amber : Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roomState.isLeader ? 'Leader' : 'Member',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            32.height,

            // Box Grid (shown when playing)
            if (playbackState.isPlaying) ...[
              PocBoxGridWidget(
                currentBox: playbackState.currentBoxIndex,
                progress: playbackState.playbackProgress,
              ),
              16.height,
              Text(
                'Position: ${playbackState.currentPositionMs}ms',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                'Box: ${playbackState.currentBoxIndex + 1}/64',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ]
            // Syncing indicator
            else if (isSyncing) ...[
              16.height,
              const CircularProgressIndicator(),
              12.height,
              const Text(
                'Syncing...',
                style: TextStyle(fontSize: 16, color: Colors.orange),
              ),
            ]
            // Countdown Display
            else if (isCounting && countdownSeconds > 0)
              Text(
                '$countdownSeconds',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              )
            // Start button (leader only)
            else if (roomState.isLeader && !isStartPressed)
              GestureDetector(
                onTap: onStartPressed,
                child: TheButton(
                  text: "START",
                  color: AppStyles.darkNavy,
                  textColor: AppStyles.white,
                ),
              )
            // Waiting message (members)
            else
              const Text(
                'Waiting for leader to start...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

            32.height,
            Text(
              'isPlaying: ${roomState.isPlaying}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'serverStartTime: ${roomState.serverStartTime}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'Room ID: ${roomState.roomId}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'testing mobile data with halfway resync',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

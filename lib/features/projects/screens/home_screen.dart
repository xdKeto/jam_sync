import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/features/poc_sync/providers/room_provider.dart';
import 'package:jam_sync/features/poc_sync/services/sync_provider.dart';
import 'package:jam_sync/features/poc_sync/screens/poc_room_screen.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/the_button.dart';

Future<void> _exportMadLogs() async {
  const sessionId = 'hyx1O1jnYxS67RcBIcSt';

  debugPrint('\n========== SESSION: $sessionId ==========');

  final logsSnap = await FirebaseFirestore.instance
      .collection('poc_sessions')
      .doc(sessionId)
      .collection('logs')
      .orderBy('logSequence')
      .get();

  // Group by client
  final Map<String, List<Map<String, dynamic>>> clientLogs = {};
  for (final doc in logsSnap.docs) {
    final d = doc.data();
    final client = d['client'] as String? ?? 'unknown';
    clientLogs.putIfAbsent(client, () => []);
    clientLogs[client]!.add(d);
  }

  debugPrint('Total logs: ${logsSnap.docs.length}');
  debugPrint('Clients found: ${clientLogs.keys.toList()}');

  int clientNum = 1;
  for (final entry in clientLogs.entries) {
    debugPrint('\n---------- CLIENT $clientNum (${entry.key}) ----------');
    debugPrint('|logSequence|currentPosition|serverTimeOffset|rawOffset|');
    for (final d in entry.value) {
      debugPrint(
        // '|${d['logSequence']}|${d['currentPosition']}|${d['serverTimeOffset']}|${d['rawOffset']}|',
        '${d['currentPosition']}',
      );
    }
    clientNum++;
  }

  debugPrint('\n========== EXPORT DONE ==========');
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Init sync service
    ref.read(pocSyncServiceProvider);

    final authState = ref.watch(authStateProvider);

    void joinRoom(BuildContext context, WidgetRef ref) {
      final codeController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Join Room', style: AppStyles.staticBodyMedium),
          content: TextField(
            keyboardType: TextInputType.number,
            controller: codeController,
            decoration: const InputDecoration(
              labelText: 'Room Code',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: TheButton(
                text: 'Cancel',
                color: AppStyles.error,
                textColor: AppStyles.white,
              ),
            ),
            GestureDetector(
              onTap: () async {
                try {
                  await ref
                      .read(roomProvider.notifier)
                      .joinRoom(codeController.text);

                  // pop dialog
                  if (!context.mounted) return;
                  Navigator.pop(context);

                  // push room screen
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PocRoomScreen()),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: TheButton(text: 'Join', color: AppStyles.lightTeal),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: authState.when(
              data: (user) {
                if (user == null) return const Text('Not logged in');

                final userData = ref.watch(userProvider(user.uid));

                return userData.when(
                  data: (data) {
                    final photoURL = data?['photoURL'] ?? '';
                    final displayName = data?['displayName'] ?? 'User';

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 64,
                          backgroundImage: photoURL.startsWith('assets/')
                              ? AssetImage(photoURL) as ImageProvider
                              : NetworkImage(photoURL),
                        ),
                        16.height,
                        // Name
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        8.height,
                        Text(user.email ?? ''),
                        8.height,
                        GestureDetector(
                          onTap: () async {
                            try {
                              await ref
                                  .read(roomProvider.notifier)
                                  .createRoom();

                              // push room screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PocRoomScreen(),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                          child: TheButton(
                            text: "Create Room",
                            color: AppStyles.lightTeal,
                          ),
                        ),
                        8.height,
                        GestureDetector(
                          onTap: () => joinRoom(context, ref),
                          child: TheButton(
                            text: "Join Room",
                            color: AppStyles.lightTeal,
                          ),
                        ),
                        8.height,
                        GestureDetector(
                          onTap: () => _exportMadLogs(),
                          child: TheButton(
                            text: "Export MAD Logs",
                            color: AppStyles.darkNavy,
                            textColor: AppStyles.white,
                          ),
                        ),
                        32.height, // Logout Button
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(authNotifierProvider.notifier).signOut();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Error: $e'),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Error: $e'),
            ),
          ),
        ),
      ),
    );
  }
}

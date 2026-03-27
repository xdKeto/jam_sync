import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/features/home/providers/projects_provider.dart';
import 'package:jam_sync/features/home/widgets/home_top_bar.dart';
import 'package:jam_sync/features/home/widgets/project_card.dart';
import 'package:jam_sync/features/home/widgets/user_card.dart';
import 'package:jam_sync/features/score_canvas/providers/room_provider.dart';
import 'package:jam_sync/features/score_canvas/screens/score_canvas_screen.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/utils/time_ago_helper.dart';
import 'package:jam_sync/shared/widgets/background_gradient.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HomeTopBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: authState.when(
                data: (user) {
                  if (user == null) return const Text('Not logged in');

                  final userData = ref.watch(userProvider(user.uid));

                  return userData.when(
                    data: (data) {
                      final photoURL = data?['photoURL'] ?? '';
                      final displayName = data?['displayName'] ?? 'User';

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(userProvider(user.uid));
                          ref.invalidate(projectsProvider);
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UserCard(name: displayName, photoURL: photoURL),
                                16.height,
                                Text("Recent Projects", style: AppStyles.h2(context)),
                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                //   children: [
                                //     Text(
                                //       "See all",
                                //       style: AppStyles.bodySmall(context).copyWith(
                                //         color: AppStyles.grey600,
                                //         decoration: TextDecoration.underline,
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                12.height,
                                ref
                                    .watch(projectsProvider)
                                    .when(
                                      data: (projects) {
                                        if (projects.isEmpty) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 20),
                                            child: Text(
                                              "No projects found. Create one or join a room!",
                                              style: AppStyles.bodyMedium(context),
                                            ),
                                          );
                                        }
                                        final recentProjects = projects.take(3).toList();
                                        return Column(
                                          children: recentProjects
                                              .map(
                                                (p) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 10),
                                                  child: GestureDetector(
                                                    onTap: () async {
                                                      debugPrint("Project tapped: ${p.title}");

                                                      final userId = ref.read(authNotifierProvider.notifier).getCurrentUser()!.uid;

                                                      await ref.read(roomProvider.notifier).joinExistingRoom(
                                                        roomCode: p.roomCode,
                                                        userID: userId,
                                                      );

                                                      if (!context.mounted) return;

                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => ScoreCanvasScreen(
                                                            projectID: p.id,
                                                            roomCode: p.roomCode,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: ProjectCard(
                                                      title: p.title,
                                                      creatorId: p.createdBy,
                                                      roomCode: p.roomCode,
                                                      timeAgo: timeAgoFromDate(p.createdAt ?? DateTime.now()),
                                                      participants: p.participants,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        );
                                      },
                                      loading: () => const Center(child: CircularProgressIndicator()),
                                      error: (e, s) => Text('Error loading projects: $e'),
                                    ),
                              ],
                            ),
                          ],
                        ),
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
      ),
    );
  }
}

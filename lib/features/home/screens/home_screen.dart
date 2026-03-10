import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/features/home/widgets/home_top_bar.dart';
import 'package:jam_sync/features/home/widgets/project_card.dart';
import 'package:jam_sync/features/home/widgets/user_card.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
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

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UserCard(name: displayName, photoURL: photoURL),
                          16.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Recent Projects",
                                style: AppStyles.h2(context),
                              ),
                              Text(
                                "See all",
                                style: AppStyles.bodySmall(context).copyWith(
                                  color: AppStyles.grey600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                          12.height,
                          ...List.generate(3, (index) {
                            final projects = [
                              {
                                'title': 'Summer Vibes Jam',
                                'bpm': 120,
                                'ts': '4/4',
                                'time': '2 hours ago',
                              },
                              {
                                'title': 'Chill Lofi Beat',
                                'bpm': 85,
                                'ts': '4/4',
                                'time': '5 hours ago',
                              },
                              {
                                'title': 'Rock Anthem Draft',
                                'bpm': 140,
                                'ts': '3/4',
                                'time': '1 day ago',
                              },
                            ];
                            final p = projects[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ProjectCard(
                                title: p['title'] as String,
                                bpm: p['bpm'] as int,
                                timeSignature: p['ts'] as String,
                                timeAgo: p['time'] as String,
                                participantAvatarUrls: [photoURL],
                              ),
                            );
                          }),
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
      ),
    );
  }
}

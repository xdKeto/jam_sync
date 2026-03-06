import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles.paleBlue,
            AppStyles.lightTeal,
            // AppStyles.mediumBlue,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
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
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(user.email ?? ''),
                      const SizedBox(height: 32),
                      // Logout Button
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
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/features/auth/screens/login_screen.dart';
import 'package:jam_sync/features/auth/screens/profile_form_screen.dart';
import 'package:jam_sync/shared/widgets/error_screen.dart';
import 'package:jam_sync/shared/widgets/splash_screen.dart';
import 'package:jam_sync/features/projects/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Jam Sync',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (user) {
          if (user == null) return LoginScreen();

          final isNewUser = ref.watch(isNewUserProvider);
          return isNewUser.when(
            data: (isNew) => isNew ? ProfileFormScreen() : HomeScreen(),
            error: (e, s) {
              return ErrorScreen();
            },
            loading: () {
              return SplashScreen();
            },
          );
        },

        loading: () {
          return SplashScreen();
        },
        error: (e, s) {
          return ErrorScreen();
        },
      ),
    );
  }
}

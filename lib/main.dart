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
    url: 'https://hulqxdpctueedviciken.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1bHF4ZHBjdHVlZWR2aWNpa2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4NzY4NDksImV4cCI6MjA4NDQ1Mjg0OX0.Mk5hFfizbXzZYgJWik4x1TeiKtZ050JVGVEc7CcA1Ds',
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
      debugShowCheckedModeBanner: false,
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
              Future.delayed(const Duration(seconds: 5));

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

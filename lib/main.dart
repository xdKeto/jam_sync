import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/features/auth/screens/login_screen.dart';
import 'package:jam_sync/features/auth/screens/profile_form_screen.dart';
import 'package:jam_sync/shared/utils/app_init_provider.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/widgets/error_screen.dart';
import 'package:jam_sync/shared/widgets/splash_screen.dart';
import 'package:jam_sync/shared/widgets/home_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  // await Supabase.initialize(
  //   url: 'https://hulqxdpctueedviciken.supabase.co',
  //   anonKey:
  //       'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1bHF4ZHBjdHVlZWR2aWNpa2VuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4NzY4NDksImV4cCI6MjA4NDQ1Mjg0OX0.Mk5hFfizbXzZYgJWik4x1TeiKtZ050JVGVEc7CcA1Ds',
  // );
  

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInit = ref.watch(appInitProvider);

    return MaterialApp(
      title: 'Jam Sync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SansFrancisco',
        colorScheme: ColorScheme.fromSeed(seedColor: AppStyles.darkNavy),
        useMaterial3: true,
      ),
      home: appInit.when(
        loading: () => const SplashScreen(),
        error: (e, s) => const ErrorScreen(),
        data: (_) {
          final authState = ref.watch(authStateProvider);
          return authState.when(
            data: (user) {
              if (user == null) return LoginScreen();

              final isNewUser = ref.watch(isNewUserProvider);
              return isNewUser.when(
                data: (isNew) => isNew ? ProfileFormScreen() : const HomeNav(),
                error: (e, s) => const ErrorScreen(),
                loading: () => const SplashScreen(),
              );
            },
            loading: () => const SplashScreen(),
            error: (e, s) => const ErrorScreen(),
          );
        },
      ),
    );
  }
}

// :) shutdown /r /f /t 0
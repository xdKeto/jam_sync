import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/features/auth/widgets/google_button.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/background_gradient.dart';
import 'package:jam_sync/shared/widgets/loading_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BackgroundGradient(
          child: Scaffold(
            backgroundColor: AppStyles.lightTeal,
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    6.height,
                    Text('Welcome to JamSync', style: AppStyles.h2(context)),
                    6.height,
                    Text(
                      'Collaborate on music in real-time with digital music sheet.',
                      style: AppStyles.bodyMedium(context),
                      textAlign: TextAlign.center,
                    ),
                    16.height,
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: InkWell(
                        onTap: _isLoading ? null : _handleSignIn,
                        child: GoogleButton(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading) const LoadingScreen(),
      ],
    );
  }
}

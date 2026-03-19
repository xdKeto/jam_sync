import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/background_gradient.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: AppStyles.lightTeal,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                  ),
                ),
                8.height,
                Text('Welcome to JamSync', style: AppStyles.h2(context)),
                6.height,
                Text(
                  'Collaborate in real-time with digital music sheet.',
                  style: AppStyles.bodyMedium(context),
                  textAlign: TextAlign.center,
                ),
                16.height,
                LoadingAnimationWidget.staggeredDotsWave(color: AppStyles.white, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

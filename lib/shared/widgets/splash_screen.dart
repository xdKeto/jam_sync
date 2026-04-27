import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/background_gradient.dart';
import 'package:jam_sync/shared/widgets/logo_widget.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LogoWidget(),
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

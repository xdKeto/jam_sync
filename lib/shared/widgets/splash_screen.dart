import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Text('Welcome to JamSync', style: AppStyles.h1(context)),
          6.height,
          Text(
            'Collaborate on music in real-time with digital music sheet.',
            style: AppStyles.bodyMedium(context),
          ),
          8.height,
          LoadingAnimationWidget.staggeredDotsWave(
            color: AppStyles.white,
            size: 24,
          ),
        ],
      ),
    );
  }
}

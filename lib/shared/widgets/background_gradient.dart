import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class BackgroundGradient extends StatelessWidget {
  const BackgroundGradient({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
      child: child,
    );
  }
}

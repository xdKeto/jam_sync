import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required VoidCallback action});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppStyles.grey100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset('assets/images/google.png', width: 24, height: 24),
          12.width,
          Text(
            'Sign in with Google',
            style: AppStyles.button(context).copyWith(color: AppStyles.black),
          ),
        ],
      ),
    );
  }
}

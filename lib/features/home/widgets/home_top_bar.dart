import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      actionsPadding: const EdgeInsets.all(12),
      actions: [
        InkWell(
          onTap: () {
            debugPrint('Notification clicked');
          },
          child: Icon(
            Icons.notifications_none_rounded,
            color: AppStyles.grey800,
            size: 28,
          ),
        ),
        16.width,
        InkWell(
          onTap: () {
            debugPrint('Settings clicked');
          },
          child: Icon(
            Icons.settings_outlined,
            color: AppStyles.grey800,
            size: 28,
          ),
        ),
      ],
    );
  }
}

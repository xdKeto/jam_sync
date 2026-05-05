import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';

import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/dialog_helpers.dart';

class UserCard extends ConsumerStatefulWidget {
  const UserCard({super.key, required this.name, required this.photoURL});

  final String name;
  final String photoURL;

  @override
  ConsumerState<UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<UserCard> {
  Future<bool> logout() async {
    return showConfirmDialog(context, title: 'Logout?', content: 'Are you sure?', confirmText: 'Logout');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppStyles.whiteBox(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            decoration: const BoxDecoration(color: AppStyles.black, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 38,
              backgroundImage: widget.photoURL.startsWith('assets/')
                  ? AssetImage(widget.photoURL) as ImageProvider
                  : NetworkImage(widget.photoURL),
            ),
          ),
          12.width,
          GestureDetector(
            onTap: () async {
              bool isLogout = await logout();
              if (isLogout) {
                await ref.read(authNotifierProvider.notifier).signOut();
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: AppStyles.h3(context).copyWith(color: AppStyles.grey900)),
                Text(
                  "Logout",
                  style: AppStyles.bodySmall(
                    context,
                  ).copyWith(color: AppStyles.grey600, decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.name, required this.photoURL});

  final String name;
  final String photoURL;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppStyles.whiteBox(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            decoration: const BoxDecoration(
              color: AppStyles.black,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundImage: photoURL.startsWith('assets/')
                  ? AssetImage(photoURL) as ImageProvider
                  : NetworkImage(photoURL),
            ),
          ),
          12.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppStyles.h3(context).copyWith(color: AppStyles.grey900),
              ),
              Text(
                "Edit Profile",
                style: AppStyles.bodySmall(context).copyWith(
                  color: AppStyles.grey600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

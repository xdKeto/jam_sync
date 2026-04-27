import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/avatar_stack.dart';

class ProjectCard extends ConsumerWidget {
  final String title;
  final String creatorId;
  final String roomCode;
  final String timeAgo;
  final List<String> participants;

  const ProjectCard({
    super.key,
    required this.title,
    required this.creatorId,
    required this.roomCode,
    required this.timeAgo,
    required this.participants,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorData = ref.watch(userProvider(creatorId));
    final creatorName = creatorData.when(
      data: (data) => data?['displayName'] as String? ?? 'Unknown User',
      loading: () => '...',
      error: (_, _) => 'Error',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.whiteBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.h4(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          8.height,
          Row(
            children: [
              Icon(Icons.person_rounded, size: 16, color: AppStyles.skyBlue),
              4.width,
              Text(
                '$creatorName • $roomCode',
                style: AppStyles.bodySmall(context),
              ),
            ],
          ),
          4.height,
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppStyles.grey500,
              ),
              4.width,
              Text(timeAgo, style: AppStyles.bodySmall(context)),
              const Spacer(),
              AvatarStack(participants: participants),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

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
              const SizedBox(width: 4),
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
              const SizedBox(width: 4),
              Text(timeAgo, style: AppStyles.bodySmall(context)),
              const Spacer(),
              _buildAvatarStack(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    const double avatarSize = 28;
    const double overlap = 10;
    final int count = participants.length;

    if (count == 0) return const SizedBox.shrink();

    final double totalWidth = avatarSize + (count - 1) * (avatarSize - overlap);

    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        children: List.generate(count, (index) {
          final uid = participants[index];
          return Positioned(
            left: index * (avatarSize - overlap),
            child: ParticipantAvatar(uid: uid, size: avatarSize),
          );
        }),
      ),
    );
  }
}

class ParticipantAvatar extends ConsumerWidget {
  final String uid;
  final double size;

  const ParticipantAvatar({super.key, required this.uid, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userProvider(uid));

    return userData.when(
      data: (data) {
        final url = data?['photoURL'] as String? ?? '';
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppStyles.white, width: 2),
            color: AppStyles.grey300,
          ),
          child: ClipOval(
            child: url.isNotEmpty
                ? Image(
                    image: url.startsWith('assets/')
                        ? AssetImage(url) as ImageProvider
                        : NetworkImage(url),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, size: 14, color: Colors.white),
                  )
                : const Icon(Icons.person, size: 14, color: Colors.white),
          ),
        );
      },
      loading: () => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppStyles.white, width: 2),
          color: AppStyles.grey300,
        ),
      ),
      error: (error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppStyles.white, width: 2),
          color: AppStyles.grey300,
        ),
        child: const Icon(Icons.error_outline, size: 14, color: Colors.white),
      ),
    );
  }
}

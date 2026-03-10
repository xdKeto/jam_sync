import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final int bpm;
  final String timeSignature;
  final String timeAgo;
  final List<String> participantAvatarUrls;

  const ProjectCard({
    super.key,
    required this.title,
    required this.bpm,
    required this.timeSignature,
    required this.timeAgo,
    required this.participantAvatarUrls,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(
                Icons.music_note_rounded,
                size: 16,
                color: AppStyles.skyBlue,
              ),
              const SizedBox(width: 4),
              Text(
                '$bpm BPM • $timeSignature',
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
    final int count = participantAvatarUrls.length;

    if (count == 0) return const SizedBox.shrink();

    final double totalWidth = avatarSize + (count - 1) * (avatarSize - overlap);

    return SizedBox(
      width: totalWidth,
      height: avatarSize,
      child: Stack(
        children: List.generate(count, (index) {
          final url = participantAvatarUrls[index];
          return Positioned(
            left: index * (avatarSize - overlap),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppStyles.white, width: 2),
              ),
              child: ClipOval(
                child: url.isNotEmpty
                    ? Image(
                        image: url.startsWith('assets/')
                            ? AssetImage(url)
                            : NetworkImage(url),
                        width: avatarSize,
                        height: avatarSize,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultAvatar(),
                      )
                    : _defaultAvatar(),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppStyles.grey300,
      child: const Icon(Icons.person, size: 14, color: Colors.white),
    );
  }
}

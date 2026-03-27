import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/features/home/providers/projects_provider.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/features/score_canvas/providers/room_provider.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/participant_avatar.dart';

class ProjectListCard extends ConsumerWidget {
  final String projectId;
  final String title;
  final String creatorId;
  final String roomCode;
  final String timeAgo;
  final List<String> participants;

  const ProjectListCard({
    super.key,
    required this.projectId,
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
      padding: const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 8),
      decoration: AppStyles.whiteBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.h4(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                height: 24,
                width: 32,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, color: AppStyles.grey500),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Project'),
                          content: const Text(
                            'Are you sure you want to delete this project? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final roomState = ref.read(roomProvider);
                        if (roomState.roomID == projectId) {
                          ref.read(roomProvider.notifier).leaveRoom();
                        }
                        ref.invalidate(canvasesStreamProvider(projectId));
                        await ref.read(projectRepositoryProvider).deleteProject(projectId);

                        if (!context.mounted) return;
                        ref.invalidate(projectsProvider);
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          4.height,
          Row(
            children: [
              Icon(Icons.person_rounded, size: 16, color: AppStyles.skyBlue),
              4.width,
              Text('$creatorName • $roomCode', style: AppStyles.bodySmall(context)),
            ],
          ),
          4.height,
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: AppStyles.grey500),
              4.width,
              Text(timeAgo, style: AppStyles.bodySmall(context)),
              const Spacer(),
              Padding(padding: const EdgeInsets.only(right: 8.0), child: _buildAvatarStack()),
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

import 'package:flutter/material.dart';
import 'package:jam_sync/shared/widgets/participant_avatar.dart';

class AvatarStack extends StatelessWidget {
  final List<String> participants;
  const AvatarStack({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
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

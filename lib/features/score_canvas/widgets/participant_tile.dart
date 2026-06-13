import 'package:flutter/material.dart';
import 'package:jam_sync/shared/models/participant_info_model.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class ParticipantTile extends StatelessWidget {
  final ParticipantInfo participant;

  const ParticipantTile({super.key, required this.participant});

  Color get statusColor => participant.isOnline ? AppStyles.success : AppStyles.grey500;

  String get latencyLabel {
    if (!participant.isOnline) return 'Offline';
    final ms = participant.latencyMs ?? 0;
    if (ms == 0) return 'Measuring...';
    return '${ms}ms';
  }

  Color get latencyColor {
    if (!participant.isOnline) return AppStyles.grey600;
    final ms = participant.latencyMs ?? 0;
    if (ms == 0) return AppStyles.grey500;
    if (ms < 150) return AppStyles.success;
    if (ms < 300) return AppStyles.warning;
    return AppStyles.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppStyles.paleBlue.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: participant.isLeader
              ? AppStyles.mediumBlue.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: participant.photoURL != null
                    ? (participant.photoURL!.startsWith('assets/')
                          ? AssetImage(participant.photoURL!) as ImageProvider
                          : NetworkImage(participant.photoURL!))
                    : null,
                child: participant.photoURL == null
                    ? const Icon(Icons.person, size: 30, color: AppStyles.white)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppStyles.darkNavy, width: 2),
                  ),
                ),
              ),
            ],
          ),
          14.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        participant.displayName,
                        style: AppStyles.h5(context).copyWith(color: AppStyles.darkNavy),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (participant.isLeader) ...[
                      8.width,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppStyles.mediumBlue.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Leader',
                          style: AppStyles.labelSmall(
                            context,
                          ).copyWith(color: AppStyles.darkNavy, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    // if (!participant.isLeader) ...[
                    //   8.width,
                    //   Icon(Icons.more_vert, color: AppStyles.grey500, size: 20),
                    // ],
                  ],
                ),
                2.height,
                Text(
                  participant.isOnline ? 'Online' : 'Offline',
                  style: AppStyles.bodySmall(context).copyWith(color: statusColor),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: latencyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.signal_cellular_alt, size: 14, color: latencyColor),
                    4.width,
                    Text(
                      latencyLabel,
                      style: AppStyles.labelSmall(context).copyWith(color: latencyColor),
                    ),
                  ],
                ),
              ),
              6.height, 
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    participant.isReady ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: participant.isReady ? AppStyles.success : AppStyles.grey600,
                  ),
                  4.width,
                  Text(
                    participant.isReady ? 'Ready' : 'Not Ready',
                    style: AppStyles.labelSmall(
                      context,
                    ).copyWith(color: participant.isReady ? AppStyles.success : AppStyles.grey600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

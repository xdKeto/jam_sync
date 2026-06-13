import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/playback_provider.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class PlaybackControls extends ConsumerStatefulWidget {
  final bool isVisible;
  final String roomCode;
  final PlaybackPhase phase;
  final bool isLeader;
  final VoidCallback? onClose;
  final VoidCallback? onStop;
  final double playbackProgress;

  const PlaybackControls({
    super.key,
    required this.isVisible,
    required this.roomCode,
    required this.phase,
    required this.isLeader,
    this.onClose,
    this.onStop,
    required this.playbackProgress,
  });

  @override
  ConsumerState<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends ConsumerState<PlaybackControls> {
  void confirmStop() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Stop Playback?', style: AppStyles.h3(ctx)),
        content: Text(
          'This will stop playback for all participants.',
          style: AppStyles.bodyMedium(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onStop?.call();
            },
            child: Text('Stop', style: TextStyle(color: AppStyles.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        offset: widget.isVisible ? Offset.zero : Offset(0, 1),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: widget.isVisible ? 1 : 0,
          duration: Duration(milliseconds: 300),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppStyles.darkNavy),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhaseIndicator(phase: widget.phase),
                  // 8.height,
                  // if (widget.phase == PlaybackPhase.playing)
                  //   Padding(
                  //     padding: EdgeInsets.symmetric(horizontal: 16),
                  //     child: ClipRRect(
                  //       borderRadius: BorderRadiusGeometry.circular(4),
                  //       child: LinearProgressIndicator(
                  //         value: widget.playbackProgress,
                  //         backgroundColor: AppStyles.grey400,
                  //         valueColor: AlwaysStoppedAnimation(
                  //           AppStyles.warning,
                  //         ),
                  //         minHeight: 4,
                  //       ),
                  //     ),
                  //   ),
                  // Consumer(builder: (context, ref, _) {
                  //   final syncService = ref.read(syncServiceProvider);

                  // }),
                  12.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.phase == PlaybackPhase.playing &&
                          widget.isLeader)
                        ControlButton(
                          icon: Icons.stop,
                          label: 'Stop',
                          color: AppStyles.error,
                          onTap: confirmStop,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PhaseIndicator extends StatelessWidget {
  final PlaybackPhase phase;

  const PhaseIndicator({super.key, required this.phase});

  String get label {
    switch (phase) {
      case PlaybackPhase.idle:
        return 'Ready';
      case PlaybackPhase.syncing:
        return 'Syncing...';
      case PlaybackPhase.countdown:
        return 'Get Ready!';
      case PlaybackPhase.playing:
        return 'Playing';
      case PlaybackPhase.ended:
        return 'Finished';
    }
  }

  Color get color {
    switch (phase) {
      case PlaybackPhase.idle:
        return AppStyles.grey400;
      case PlaybackPhase.syncing:
        return AppStyles.warning;
      case PlaybackPhase.countdown:
        return AppStyles.lightTeal;
      case PlaybackPhase.playing:
        return AppStyles.success;
      case PlaybackPhase.ended:
        return AppStyles.grey400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppStyles.bodySmall(
          context,
        ).copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppStyles.grey900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            8.width,
            Text(
              label,
              style: AppStyles.bodyMedium(context).copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

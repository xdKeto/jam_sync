import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/playback_provider.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class CountdownOverlay extends ConsumerWidget {
  final PlaybackProviderParams params;

  const CountdownOverlay({super.key, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playbackProvider(params));

    if (state.phase == PlaybackPhase.idle) {
      return SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        if (state.phase == PlaybackPhase.ended) {
          Navigator.pop(context);
        }
      },
      child: Container(
        color: AppStyles.black.withValues(alpha: 0.85),
        child: buildOverlayContent(context, state),
      ),
    );
  }

  Widget buildOverlayContent(BuildContext context, PlaybackState state) {
    switch (state.phase) {
      case PlaybackPhase.syncing:
        return buildSyncingOverlay(context);
      case PlaybackPhase.countdown:
        return buildCountdownOverlay(context, state);
      case PlaybackPhase.ended:
        return buildEndedOverlay(context);
      default:
        return SizedBox.shrink();
    }
  }

  Widget buildSyncingOverlay(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppStyles.white,
              strokeWidth: 3,
            ),
          ),
          24.height,
          Text(
            "Syncing...",
            style: AppStyles.h2(context).copyWith(color: AppStyles.white),
          ),
          8.height,
          Text(
            "Please wait",
            style: AppStyles.bodyMedium(context).copyWith(color: AppStyles.grey400),
          ),
        ],
      ),
    );
  }

  Widget buildCountdownOverlay(BuildContext context, PlaybackState state) {

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(state.countdownBeat),
            tween: Tween(begin: 1.0, end: 1.15),
            duration: Duration(milliseconds: state.beatDuration.round()),
            curve: Curves.easeOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Text(
                  "${state.countdownBeat}",
                  style: TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.warning,
                  ),
                ),
              );
            },
          ),
          8.height,
          Text(
            "Get ready...",
            style: AppStyles.bodyLarge(context).copyWith(color: AppStyles.white),
          ),
          32.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 50),
                        width: constraints.maxWidth * (1 - state.beatProgress),
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppStyles.warning,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEndedOverlay(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppStyles.success, size: 64),
          16.height,
          Text(
            "Session Ended",
            style: AppStyles.h2(context).copyWith(color: AppStyles.white),
          ),
          8.height,
          Text(
            "Tap anywhere to exit",
            style: AppStyles.bodyMedium(context).copyWith(color: AppStyles.grey400),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class PlaybackCursor extends StatefulWidget {
  final double barHeight;
  final bool isPlaying;

  const PlaybackCursor({
    super.key,
    required this.barHeight,
    required this.isPlaying,
  });

  @override
  State<PlaybackCursor> createState() => _PlaybackCursorState();
}

class _PlaybackCursorState extends State<PlaybackCursor> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> opacity;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    opacity = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(PlaybackCursor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !controller.isAnimating) {
      controller.repeat(reverse: true);
    } else if (!widget.isPlaying && controller.isAnimating) {
      controller.stop();
      controller.value = 1.0;
    }
  }

  

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: opacity,
      builder: (context, child) {
        return Opacity(
          opacity: widget.isPlaying ? opacity.value : 1,
          child: Container(
            width: 6,
            height: widget.barHeight + 16,
            decoration: BoxDecoration(
              color: AppStyles.success.withValues(alpha: widget.isPlaying ? 1.0 : 0.4),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}

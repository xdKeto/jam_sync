import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class PlaybackControls extends ConsumerStatefulWidget {
  final bool isVisible;
  final String roomCode;
  const PlaybackControls({super.key, required this.isVisible, required this.roomCode});

  @override
  ConsumerState<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends ConsumerState<PlaybackControls> {
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
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppStyles.black.withValues(alpha: 0.7)],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.close, color: AppStyles.white),
                  ),
                  Spacer(),
                  Text("Room: ${widget.roomCode}", style: TextStyle(color: AppStyles.white)),
                  Spacer(),
                  48.width,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

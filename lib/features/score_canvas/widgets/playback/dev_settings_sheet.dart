import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/the_button.dart';

class PlaybackSettings {
  final bool enableHalfwayResync;
  final int countdownBeats;

  const PlaybackSettings({
    this.enableHalfwayResync = false,
    this.countdownBeats = 4,
  });

  PlaybackSettings copyWith({
    bool? enableHalfwayResync,
    int? countdownBeats,
  }) {
    return PlaybackSettings(
      enableHalfwayResync: enableHalfwayResync ?? this.enableHalfwayResync,
      countdownBeats: countdownBeats ?? this.countdownBeats,
    );
  }
}

class DevSettingsSheet extends StatefulWidget {
  final int defaultCountdownBeats;

  const DevSettingsSheet({
    super.key,
    this.defaultCountdownBeats = 4,
  });

  @override
  State<DevSettingsSheet> createState() => _DevSettingsSheetState();

  static Future<PlaybackSettings?> show(BuildContext context, {int defaultCountdownBeats = 4}) {
    return showModalBottomSheet<PlaybackSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DevSettingsSheet(defaultCountdownBeats: defaultCountdownBeats),
    );
  }
}

class _DevSettingsSheetState extends State<DevSettingsSheet> {
  late bool _enableHalfwayResync;
  late int _countdownBeats;

  @override
  void initState() {
    super.initState();
    _enableHalfwayResync = false;
    _countdownBeats = widget.defaultCountdownBeats;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.darkNavy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppStyles.grey600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          16.height,
          Text(
            "Playback Settings (raw offset)",
            style: AppStyles.h3(context).copyWith(color: AppStyles.white),
            textAlign: TextAlign.center,
          ),
          24.height,
          _buildToggle(
            title: "Halfway Resync",
            subtitle: "Resinkronisasi setengah lagu",
            value: _enableHalfwayResync,
            onChanged: (v) => setState(() => _enableHalfwayResync = v),
          ),
          24.height,
          Text(
            "Countdown Beats",
            style: AppStyles.bodyLarge(context).copyWith(color: AppStyles.white),
          ),
          8.height,
          Row(
            children: [
              _beatOption(2),
              12.width,
              _beatOption(4),
              12.width,
              _beatOption(8),
            ],
          ),
          32.height,
          GestureDetector(
            onTap: () {
              Navigator.pop(
                context,
                PlaybackSettings(
                  enableHalfwayResync: _enableHalfwayResync,
                  countdownBeats: _countdownBeats,
                ),
              );
            },
            child: TheButton(
              text: "START PLAYBACK",
              color: AppStyles.lightTeal,
              textColor: AppStyles.darkNavy,
              vertPadding: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppStyles.bodyLarge(context).copyWith(color: AppStyles.white),
              ),
              2.height,
              Text(
                subtitle,
                style: AppStyles.bodySmall(context).copyWith(color: AppStyles.grey400),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppStyles.lightTeal,
        ),
      ],
    );
  }

  Widget _beatOption(int beats) {
    final isSelected = _countdownBeats == beats;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _countdownBeats = beats),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppStyles.lightTeal : AppStyles.grey800,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "$beats",
            style: AppStyles.h3(context).copyWith(
              color: isSelected ? AppStyles.darkNavy : AppStyles.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
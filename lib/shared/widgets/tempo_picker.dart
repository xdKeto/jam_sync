import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class TempoPicker extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const TempoPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<TempoPicker> createState() => _TempoPickerState();
}

class _TempoPickerState extends State<TempoPicker> {
  late double localValue;

  @override
  void initState() {
    super.initState();
    localValue = widget.value;
  }

  @override
  void didUpdateWidget(TempoPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      localValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyles.whiteBox(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Tempo (BPM)", style: AppStyles.h5(context)),
              Text(
                " - nilai ini bisa diubah nanti",
                style: AppStyles.labelSmall(context),
              ),
            ],
          ),
          12.height,
          Row(
            children: [
              Expanded(
                child: SfSlider(
                  min: 40.0,
                  max: 200.0,
                  value: localValue,
                  interval: 40,
                  stepSize: 1.0,
                  showTicks: true,
                  showLabels: true,
                  enableTooltip: true,
                  minorTicksPerInterval: 3,
                  activeColor: AppStyles.darkNavy,
                  tooltipTextFormatterCallback: (dynamic actualValue, String formattedText) {
                    return (actualValue as double).round().toString();
                  },
                  labelFormatterCallback: (dynamic actualValue, String formattedText) {
                    return (actualValue as double).round().toString();
                  },
                  onChanged: widget.enabled
                      ? (dynamic value) {
                          setState(() {
                            localValue = (value as double).roundToDouble();
                          });
                          widget.onChanged(localValue);
                        }
                      : null,
                ),
              ),
              8.width,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_drop_up, size: 32),
                    onPressed: widget.enabled && localValue < 200.0
                        ? () {
                            setState(() {
                              localValue += 1.0;
                            });
                            widget.onChanged(localValue);
                          }
                        : null,
                  ),
                  Text(
                    localValue.round().toString(),
                    style: AppStyles.h3(context),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_drop_down, size: 32),
                    onPressed: widget.enabled && localValue > 40.0
                        ? () {
                            setState(() {
                              localValue -= 1.0;
                            });
                            widget.onChanged(localValue);
                          }
                        : null,
                  ),
                ],
              ),
              16.width,
            ],
          ),
        ],
      ),
    );
  }
}

class TempoControl extends ConsumerStatefulWidget {
  final int initialTempo;
  final String projectID;
  final String canvasID;

  const TempoControl({
    super.key,
    required this.initialTempo,
    required this.projectID,
    required this.canvasID,
  });

  @override
  ConsumerState<TempoControl> createState() => _TempoControlState();
}

class _TempoControlState extends ConsumerState<TempoControl> {
  late double _localTempo;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _localTempo = widget.initialTempo.toDouble();
  }

  @override
  void didUpdateWidget(TempoControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTempo != widget.initialTempo) {
      _localTempo = widget.initialTempo.toDouble();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _debounceTimer?.cancel();
  }

  void _onTempoChanged(double value) {
    setState(() {
      _localTempo = value;
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(projectRepositoryProvider).updateCanvasTempo(
            projectID: widget.projectID,
            canvasID: widget.canvasID,
            tempo: value.round(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyles.whiteBox(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
                Iconsax.music,
                size: 18,
                color: AppStyles.darkNavy,
              ),
          Text(
            ' ${_localTempo.round()}',
            style: AppStyles.bodySmall(context).copyWith(
              color: AppStyles.darkNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 40),
            child: SizedBox(
              width: 150,
              height: 40,
              child: SfSlider(
                min: 40.0,
                max: 200.0,
                value: _localTempo,
                interval: 40,
                stepSize: 1.0,
                showTicks: false,
                showLabels: false,
                enableTooltip: false,
                minorTicksPerInterval: 3,
                activeColor: AppStyles.mediumBlue,
                inactiveColor: AppStyles.grey400,
                onChanged: (dynamic value) => _onTempoChanged(value as double),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TempoSheet extends ConsumerStatefulWidget {
  final int initialTempo;
  final String projectID;
  final String canvasID;

  const TempoSheet({
    super.key,
    required this.initialTempo,
    required this.projectID,
    required this.canvasID,
  });

  @override
  ConsumerState<TempoSheet> createState() => _TempoSheetState();
}

class _TempoSheetState extends ConsumerState<TempoSheet> {
  late double _localTempo;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _localTempo = widget.initialTempo.toDouble();
  }

  @override
  void didUpdateWidget(TempoSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTempo != widget.initialTempo) {
      _localTempo = widget.initialTempo.toDouble();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _debounceTimer?.cancel();
  }

  void _onTempoChanged(double value) {
    setState(() {
      _localTempo = value;
    });
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(projectRepositoryProvider).updateCanvasTempo(
            projectID: widget.projectID,
            canvasID: widget.canvasID,
            tempo: value.round(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppStyles.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppStyles.grey400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          16.height,
          Text("Tempo", style: AppStyles.h5(context)),
          16.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: SfSlider(
                    min: 40.0,
                    max: 200.0,
                    value: _localTempo,
                    interval: 40,
                    stepSize: 1.0,
                    showTicks: true,
                    showLabels: true,
                    enableTooltip: true,
                    minorTicksPerInterval: 3,
                    activeColor: AppStyles.darkNavy,
                    tooltipTextFormatterCallback: (dynamic actualValue, String formattedText) {
                      return (actualValue as double).round().toString();
                    },
                    labelFormatterCallback: (dynamic actualValue, String formattedText) {
                      return (actualValue as double).round().toString();
                    },
                    onChanged: (dynamic value) {
                      _onTempoChanged((value as double).roundToDouble());
                    },
                  ),
                ),
                16.width,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_drop_up, size: 28),
                      onPressed: _localTempo < 200.0
                          ? () => _onTempoChanged(_localTempo + 1)
                          : null,
                    ),
                    Text(
                      _localTempo.round().toString(),
                      style: AppStyles.h3(context),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_drop_down, size: 28),
                      onPressed: _localTempo > 40.0
                          ? () => _onTempoChanged(_localTempo - 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          16.height,
        ],
      ),
    );
  }
}

class TempoIconButton extends StatelessWidget {
  final int tempo;
  final VoidCallback onTap;

  const TempoIconButton({
    super.key,
    required this.tempo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppStyles.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.music,
                size: 18,
                color: AppStyles.darkNavy,
              ),
              6.width,
              Text(
                tempo.toString(),
                style: AppStyles.bodySmall(context).copyWith(
                  color: AppStyles.darkNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class AddBarDialog extends ConsumerStatefulWidget {
  final String timeSignature;
  final bool isEdit;
  final int? initialBeatCount;

  const AddBarDialog({
    super.key,
    required this.timeSignature,
    this.isEdit = false,
    this.initialBeatCount,
  });

  @override
  ConsumerState<AddBarDialog> createState() => _AddBarDialogState();
}

class _AddBarDialogState extends ConsumerState<AddBarDialog> {
  late int selectedBeatCount;
  late int maxBeats;

  @override
  void initState() {
    super.initState();
    maxBeats = beatsPerBar(widget.timeSignature);
    selectedBeatCount = (widget.initialBeatCount ?? maxBeats).clamp(1, maxBeats);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEdit ? 'Edit Beat Count' : 'Add Bar',
        style: AppStyles.h3(context),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Beat Count:', style: AppStyles.bodyMedium(context)),
          8.height,
          DropdownButtonFormField<int>(
            initialValue: selectedBeatCount,
            decoration: AppStyles.formBox,
            items: List.generate(maxBeats, (index) {
              final count = index + 1;
              return DropdownMenuItem(
                value: count,
                child: Text('$count Beats'),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedBeatCount = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedBeatCount),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.darkNavy,
            foregroundColor: AppStyles.white,
          ),
          child: Text(widget.isEdit ? 'Update' : 'Add Bar'),
        ),
      ],
    );
  }
}

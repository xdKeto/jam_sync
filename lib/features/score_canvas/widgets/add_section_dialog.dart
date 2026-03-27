import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class AddSectionDialog extends ConsumerStatefulWidget {
  const AddSectionDialog({super.key});

  @override
  ConsumerState<AddSectionDialog> createState() => _AddSectionDialogState();
}

class _AddSectionDialogState extends ConsumerState<AddSectionDialog> {
  final nameController = TextEditingController();
  final barCountController = TextEditingController(text: '4');

  @override
  void dispose() {
    nameController.dispose();
    barCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Section', style: AppStyles.h3(context)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: AppStyles.formBox.copyWith(
              labelText: 'Section Name',
              hintText: 'e.g., Verse 2, Chorus',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: barCountController,
            keyboardType: TextInputType.number,
            decoration: AppStyles.formBox.copyWith(
              labelText: 'Number of Bars',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            final count = int.tryParse(barCountController.text) ?? 4;
            if (name.isNotEmpty && count > 0) {
              Navigator.pop(context, {'name': name, 'barCount': count});
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.darkNavy,
            foregroundColor: AppStyles.white,
          ),
          child: const Text('Add Section'),
        ),
      ],
    );
  }
}

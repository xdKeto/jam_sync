import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

enum ChordAction { addChord, changeChord, deleteChord, addPassing, changePassing, deletePassing }

class ChordActionSheet extends StatelessWidget {
  final String currentChord;
  final String currentPassingChord;

  const ChordActionSheet({
    super.key,
    required this.currentChord,
    required this.currentPassingChord,
  });

  static Future<ChordAction?> show(
    BuildContext context, {
    String currentChord = '',
    String currentPassingChord = '',
  }) {
    return showModalBottomSheet<ChordAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppStyles.white,
      builder: (context) =>
          ChordActionSheet(currentChord: currentChord, currentPassingChord: currentPassingChord),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    ChordAction action, {
    Color color = AppStyles.textPrimary,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: AppStyles.bodyMedium(context).copyWith(color: color)),
      onTap: () => Navigator.pop(context, action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMain = currentChord.isNotEmpty;
    final bool hasPassing = currentPassingChord.isNotEmpty;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          16.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Chord Actions', style: AppStyles.h3(context)),
          ),
          const Divider(height: 32),

          // Main Chord Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Main Chord', style: AppStyles.labelSmall(context)),
          ),
          if (!hasMain)
            _buildListTile(context, Icons.add, 'Add Chord', ChordAction.addChord)
          else ...[
            _buildListTile(context, Icons.edit, 'Edit Chord', ChordAction.changeChord),
            _buildListTile(
              context,
              Icons.delete_outline,
              'Delete Chord',
              ChordAction.deleteChord,
              color: AppStyles.error,
            ),
          ],

          const Divider(),

          // Passing Chord Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Passing Chord', style: AppStyles.labelSmall(context)),
          ),
          if (!hasPassing)
            _buildListTile(
              context,
              Icons.add_circle_outline,
              'Add Passing Chord',
              ChordAction.addPassing,
            )
          else ...[
            _buildListTile(context, Icons.edit, 'Edit Passing Chord', ChordAction.changePassing),
            _buildListTile(
              context,
              Icons.delete_outline,
              'Delete Passing Chord',
              ChordAction.deletePassing,
              color: AppStyles.error,
            ),
          ],
          16.height,
        ],
      ),
    );
  }
}

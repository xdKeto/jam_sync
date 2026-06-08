import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:jam_sync/features/score_canvas/widgets/song_structure_sheet.dart';
import 'package:jam_sync/features/score_canvas/widgets/edit_section_sheet.dart';
import 'package:jam_sync/features/score_canvas/widgets/notes_sheet.dart';

class EditOptionSheet extends ConsumerWidget {
  final String projectID;
  final String canvasID;
  final String timeSignature;

  const EditOptionSheet({
    super.key,
    required this.projectID,
    required this.canvasID,
    required this.timeSignature,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Iconsax.menu),
            title: Text('Song Structure'),
            subtitle: Text('Manage sections'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                constraints: const BoxConstraints(maxWidth: double.infinity),
                builder: (_) => SongStructureSheet(
                  projectID: projectID,
                  canvasID: canvasID,
                  timeSignature: timeSignature,
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Iconsax.edit),
            title: Text('Edit Section'),
            subtitle: Text('Manage section content'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                constraints: const BoxConstraints(maxWidth: double.infinity),
                builder: (_) => EditSectionSheet(
                  projectID: projectID,
                  canvasID: canvasID,
                  timeSignature: timeSignature,
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Iconsax.note_text),
            title: Text('Notes'),
            subtitle: Text('Add annotations'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                constraints: const BoxConstraints(maxWidth: double.infinity),
                builder: (_) => NotesSheet(
                  projectID: projectID,
                  canvasID: canvasID,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

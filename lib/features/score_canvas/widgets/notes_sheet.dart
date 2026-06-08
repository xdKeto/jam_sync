import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class NotesSheet extends ConsumerStatefulWidget {
  final String projectID;
  final String canvasID;

  const NotesSheet({
    super.key,
    required this.projectID,
    required this.canvasID,
  });

  @override
  ConsumerState<NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends ConsumerState<NotesSheet> {
  Future<void> showEditDialog(String noteID, String currentText) async {
    final controller = TextEditingController(text: currentText);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Note', style: AppStyles.h3(context)),
        content: TextField(
          controller: controller,
          decoration: AppStyles.formBox.copyWith(labelText: 'Note Text'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.darkNavy,
              foregroundColor: AppStyles.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != currentText && mounted) {
      await ref
          .read(projectRepositoryProvider)
          .updateNote(
            projectID: widget.projectID,
            canvasID: widget.canvasID,
            noteID: noteID,
            data: {'text': result},
          );
    }
  }

  Future<void> confirmDelete(String noteID, String text) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note', style: AppStyles.h3(context)),
        content: Text(
          'Delete "$text"? This cannot be undone.',
          style: AppStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref
          .read(projectRepositoryProvider)
          .deleteNote(
            projectID: widget.projectID,
            canvasID: widget.canvasID,
            noteID: noteID,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(
      notesStreamProvider((
        projectID: widget.projectID,
        canvasID: widget.canvasID,
      )),
    );

    return DraggableScrollableSheet(
      initialChildSize: 1,
      minChildSize: 1,
      builder: (context, scrollController) {
        return SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: const Text('Notes'),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            body: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(child: Text('No notes available.'));
                }

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      key: ValueKey(note.id),
                      leading: Container(
                        width: 8,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEB3B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      title: Text(
                        note.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppStyles.darkNavy,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.edit, color: AppStyles.white),
                            onPressed: () => showEditDialog(note.id, note.text),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppStyles.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.delete, color: AppStyles.white),
                            onPressed: () => confirmDelete(note.id, note.text),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              error: (error, stack) {
                debugPrint("Error: $error");
                return Center(child: Text("Error: $error"));
              },
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: AppStyles.darkNavy,
              foregroundColor: AppStyles.white,
              onPressed: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (_) => const AddNoteDialog(),
                );

                if (result != null && mounted) {
                  await ref
                      .read(projectRepositoryProvider)
                      .addNote(
                        projectID: widget.projectID,
                        canvasID: widget.canvasID,
                        text: result,
                        posX: 0.5,
                        posY: 0.1,
                      );
                }
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}

class AddNoteDialog extends StatefulWidget {
  const AddNoteDialog({super.key});

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Note', style: AppStyles.h3(context)),
      content: TextField(
        controller: textController,
        decoration: AppStyles.formBox.copyWith(
          labelText: 'Note Text',
          hintText: 'e.g. "Crescendo here"',
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final text = textController.text.trim();
            if (text.isNotEmpty) {
              Navigator.pop(context, text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.darkNavy,
            foregroundColor: AppStyles.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

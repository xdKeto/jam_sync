import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/features/score_canvas/widgets/add_section_dialog.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';

class SongStructureSheet extends ConsumerStatefulWidget {
  final String projectID;
  final String canvasID;
  final String timeSignature;

  const SongStructureSheet({
    super.key,
    required this.projectID,
    required this.canvasID,
    required this.timeSignature,
  });

  @override
  ConsumerState<SongStructureSheet> createState() => _SongStructureSheetState();
}

class _SongStructureSheetState extends ConsumerState<SongStructureSheet> {
  Future<void> showRenameDialog(String sectionID, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Section', style: AppStyles.h3(context)),
        content: TextField(
          controller: controller,
          decoration: AppStyles.formBox.copyWith(labelText: 'Section Name'),
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
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result != currentName && mounted) {
      await ref
          .read(projectRepositoryProvider)
          .updateSection(
            projectID: widget.projectID,
            canvasID: widget.canvasID,
            sectionID: sectionID,
            data: {'name': result},
          );
    }
  }

  Future<void> showCopyDialog(SectionModel section) async {
    final controller = TextEditingController(text: '${section.name} Copy');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Copy Section', style: AppStyles.h3(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: AppStyles.formBox.copyWith(
                labelText: 'New Section Name',
              ),
            ),
            8.height,
            Text(
              'Bars: ${section.barCount}',
              style: AppStyles.bodyMedium(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
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
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final sectionAsync = ref.read(
        sectionsStreamProvider((
          projectID: widget.projectID,
          canvasID: widget.canvasID,
        )),
      );

      final currentSections = sectionAsync.value ?? [];
      final nextOrder = currentSections.length;
      final nextStartBar = currentSections.fold<int>(
        0,
        (prev, s) => prev + s.barCount,
      );

      await ref
          .read(projectRepositoryProvider)
          .copySection(
            projectID: widget.projectID,
            canvasID: widget.canvasID,
            sectionID: section.id,
            name: result,
            order: nextOrder,
            barCount: section.barCount,
            startBar: nextStartBar,
          );
    }
  }

  Future<void> confirmDelete(String sectionID, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Section', style: AppStyles.h3(context)),
        content: Text(
          'Delete "$name" and all its bars? This cannot be undone.',
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
          .deleteSection(
            projectID: widget.projectID,
            canvasID: widget.canvasID,
            sectionID: sectionID,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionAsync = ref.watch(
      sectionsStreamProvider((
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
              title: const Text("Song Structure"),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
            body: sectionAsync.when(
              data: (sections) {
                if (sections.isEmpty) {
                  return const Center(child: Text("No sections available."));
                }
                return ReorderableListView.builder(
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return ListTile(
                      key: ValueKey(section.id),
                      leading: Icon(Icons.drag_handle),
                      title: Text(section.name),
                      subtitle: Text("${section.barCount} bars"),
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
                            icon: Icon(Icons.edit, color: AppStyles.white),
                            onPressed: () =>
                                showRenameDialog(section.id, section.name),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppStyles.darkNavy,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(Icons.copy, color: AppStyles.white),
                            onPressed: () => showCopyDialog(section),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppStyles.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(Icons.delete, color: AppStyles.white),
                            onPressed: () =>
                                confirmDelete(section.id, section.name),
                          ),
                        ],
                      ),
                    );
                  },
                  itemCount: sections.length,
                  onReorder: (oldIndex, newIndex) async {
                    if (oldIndex < newIndex) newIndex -= 1;

                    final reordered = List<SectionModel>.from(sections);
                    final item = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, item);

                    await ref
                        .read(projectRepositoryProvider)
                        .reorderSections(
                          projectID: widget.projectID,
                          canvasID: widget.canvasID,
                          reordered: reordered,
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
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (_) => const AddSectionDialog(),
                );

                if (result != null && mounted) {
                  final currentSections = sectionAsync.value ?? [];
                  final nextOrder = currentSections.length;
                  final nextStartBar = currentSections.fold<int>(
                    0,
                    (prev, s) => prev + s.barCount,
                  );

                  await ref
                      .read(projectRepositoryProvider)
                      .addSection(
                        projectID: widget.projectID,
                        canvasID: widget.canvasID,
                        name: result['name'] as String,
                        order: nextOrder,
                        barCount: result['barCount'] as int,
                        startBar: nextStartBar,
                        timeSignature: widget.timeSignature,
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

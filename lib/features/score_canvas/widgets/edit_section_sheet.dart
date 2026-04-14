import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/shared/models/section_model.dart';
import 'package:jam_sync/shared/models/bar_model.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';
import 'package:jam_sync/features/score_canvas/widgets/add_bar_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditSectionSheet extends ConsumerStatefulWidget {
  final String projectID;
  final String canvasID;
  final String timeSignature;

  const EditSectionSheet({
    super.key,
    required this.projectID,
    required this.canvasID,
    required this.timeSignature,
  });

  @override
  ConsumerState<EditSectionSheet> createState() => _EditSectionSheetState();
}

class _EditSectionSheetState extends ConsumerState<EditSectionSheet> {
  SectionModel? selectedSection;
  List<BarModel>? _localBars;

  Future<void> confirmDeleteBar(String barId, int index) async {
    if (selectedSection == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Bar', style: AppStyles.h3(context)),
        content: Text(
          'Delete Bar ${index + 1}? This cannot be undone.',
          style: AppStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
          .deleteBar(
            projectID: widget.projectID,
            canvasID: widget.canvasID,
            sectionID: selectedSection!.id,
            barID: barId,
          );
    }
  }

  Future<void> editBeatCount(BarModel bar) async {
    if (selectedSection == null) return;

    final currentBeatCount = bar.beatCount ?? beatsPerBar(widget.timeSignature);

    final result = await showDialog<int>(
      context: context,
      builder: (_) => AddBarDialog(
        timeSignature: widget.timeSignature,
        isEdit: true,
        initialBeatCount: currentBeatCount,
      ),
    );

    if (result != null && mounted) {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      await ref
          .read(projectRepositoryProvider)
          .updateBarBeatCount(
            projectID: widget.projectID,
            canvasID: widget.canvasID,
            sectionID: selectedSection!.id,
            barID: bar.id,
            newBeatCount: result,
            currentChords: bar.chords,
            currentPassing: bar.passingChord,
            userID: userId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(
      sectionsStreamProvider((projectID: widget.projectID, canvasID: widget.canvasID)),
    );

    return PopScope(
      canPop: selectedSection == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (selectedSection != null) {
          setState(() {
            selectedSection = null;
            _localBars = null;
          });
        } else {
          Navigator.pop(context);
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 1.0,
        builder: (context, scrollController) {
          return SafeArea(
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                title: Text(selectedSection?.name ?? "Pilih Section"),
                leading: IconButton(
                  icon: Icon(selectedSection != null ? Icons.arrow_back : Icons.close),
                  onPressed: () {
                    if (selectedSection != null) {
                      setState(() {
                        selectedSection = null;
                        _localBars = null;
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              body: selectedSection == null
                  ? buildSectionPicker(sectionsAsync)
                  : buildBarEditor(selectedSection!),
              floatingActionButton: selectedSection != null
                  ? FloatingActionButton(
                      backgroundColor: AppStyles.darkNavy,
                      foregroundColor: AppStyles.white,
                      onPressed: () async {
                        final result = await showDialog<int>(
                          context: context,
                          builder: (_) => AddBarDialog(timeSignature: widget.timeSignature),
                        );

                        if (result != null && mounted) {
                          final currentBarCount = selectedSection!.barCount;
                          await ref
                              .read(projectRepositoryProvider)
                              .addBar(
                                projectID: widget.projectID,
                                canvasID: widget.canvasID,
                                sectionID: selectedSection!.id,
                                index: currentBarCount,
                                beatCount: result,
                                timeSignature: widget.timeSignature,
                              );
                        }
                      },
                      child: const Icon(Icons.add),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget buildSectionPicker(AsyncValue<List<SectionModel>> sectionsAsync) {
    return sectionsAsync.when(
      data: (sections) {
        if (sections.isEmpty) {
          return const Center(child: Text("No sections available."));
        }
        return ListView.builder(
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return ListTile(
              title: Text(section.name, style: AppStyles.bodyLarge(context)),
              subtitle: Text("${section.barCount} bars", style: AppStyles.bodySmall(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  selectedSection = section;
                  _localBars = null;
                });
              },
            );
          },
        );
      },
      error: (e, _) => Center(child: Text("Error: $e")),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget buildBarEditor(SectionModel section) {
    final barsAsync = ref.watch(
      barsStreamProvider((
        projectID: widget.projectID,
        canvasID: widget.canvasID,
        sectionID: section.id,
      )),
    );

    return barsAsync.when(
      data: (bars) {
        if (bars.isEmpty) {
          return const Center(child: Text("No bars in this section."));
        }
        final displayBars = _localBars ?? bars;

        return ReorderableListView.builder(
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) newIndex -= 1;
              _localBars = List.from(displayBars);
              final item = _localBars!.removeAt(oldIndex);
              _localBars!.insert(newIndex, item);
            });

            // ignore: unawaited_futures
            ref
                .read(projectRepositoryProvider)
                .reorderBars(
                  projectID: widget.projectID,
                  canvasID: widget.canvasID,
                  sectionID: section.id,
                  reordered: _localBars!,
                );
          },
          itemCount: displayBars.length,
          itemBuilder: (context, index) {
            final bar = displayBars[index];
            final chordSummary = bar.chords.where((c) => c.isNotEmpty).join(' | ');
            final displayBeatCount = bar.beatCount ?? beatsPerBar(widget.timeSignature);

            return ListTile(
              key: ValueKey(bar.id),
              leading: const Icon(Icons.drag_handle),
              title: Text("Bar ${index + 1}"),
              subtitle: Text(
                chordSummary.isEmpty ? "Empty" : chordSummary,
                style: AppStyles.bodySmall(
                  context,
                ).copyWith(color: AppStyles.darkNavy, fontWeight: FontWeight.w600),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionChip(
                    label: Text("$displayBeatCount beats"),
                    onPressed: () => editBeatCount(bar),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => confirmDeleteBar(bar.id, index),
                  ),
                ],
              ),
            );
          },
        );
      },
      error: (e, _) => Center(child: Text("Error: $e")),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

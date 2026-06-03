import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/features/score_canvas/widgets/add_canvas_sheet.dart';
import 'package:quickalert/quickalert.dart';

class CanvasOptionSheet extends ConsumerStatefulWidget {
  final String projectID;
  final List<CanvasModel> canvases;
  final String? selectedCanvasId;
  final ValueChanged<CanvasModel> onCanvasSelected;
  final VoidCallback? onCanvasDeleted;

  const CanvasOptionSheet({
    super.key,
    required this.projectID,
    required this.canvases,
    this.selectedCanvasId,
    required this.onCanvasSelected,
    this.onCanvasDeleted,
  });

  @override
  ConsumerState<CanvasOptionSheet> createState() => _CanvasOptionSheetState();
}

class _CanvasOptionSheetState extends ConsumerState<CanvasOptionSheet> {
  void showAddCanvasSheet() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (ctx) => AddCanvasSheet(
        projectID: widget.projectID,
        existingCanvases: widget.canvases,
        onCanvasCreated: (canvas) {
          widget.onCanvasSelected(canvas);
        },
      ),
    );
  }

  Future<void> handleDeleteCanvas(CanvasModel canvas) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sheet?'),
        content: Text(
          '"${canvas.title}" Sheet dan semua bagiannya akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(projectRepositoryProvider)
            .deleteCanvas(projectID: widget.projectID, canvasID: canvas.id);

        if (!mounted) return;

        if (widget.onCanvasDeleted != null) {
          widget.onCanvasDeleted!();
        }
      } catch (e) {
        if (!mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Gagal menghapus partitur: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = widget.canvases.length > 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pick Sheet",
            style: AppStyles.h3(context).copyWith(color: AppStyles.darkNavy),
          ),
          4.height,
          ...widget.canvases.map((canvas) {
            final isSelected =
                widget.selectedCanvasId == canvas.id ||
                (widget.selectedCanvasId == null &&
                    widget.canvases.isNotEmpty &&
                    widget.canvases.first.id == canvas.id);

            return Dismissible(
              key: Key(canvas.id),
              direction: canDelete
                  ? DismissDirection.endToStart
                  : DismissDirection.none,
              confirmDismiss: (direction) async {
                await handleDeleteCanvas(canvas);
                return false;
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.document_scanner_outlined,
                  color: AppStyles.darkNavy,
                ),
                title: Text(
                  canvas.title,
                  style: AppStyles.bodyMedium(context).copyWith(
                    color: AppStyles.darkNavy,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '♩ ${canvas.tempo.round()} BPM • ${canvas.timeSignature}',
                  style: AppStyles.labelSmall(
                    context,
                  ).copyWith(color: AppStyles.grey500),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(Icons.check, color: AppStyles.darkNavy),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppStyles.grey400,
                        ),
                        onPressed: () => handleDeleteCanvas(canvas),
                      ),
                  ],
                ),
                onTap: () {
                  widget.onCanvasSelected(canvas);
                  Navigator.pop(context);
                },
              ),
            );
          }),
          const Divider(color: AppStyles.grey300),
          ListTile(
            leading: const Icon(Icons.add, color: AppStyles.darkNavy),
            title: Text(
              "Add New",
              style: AppStyles.bodyMedium(context).copyWith(
                color: AppStyles.darkNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: showAddCanvasSheet,
          ),
        ],
      ),
    );
  }
}

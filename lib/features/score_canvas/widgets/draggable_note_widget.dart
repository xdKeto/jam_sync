import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/models/note_model.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class DraggableNoteWidget extends ConsumerStatefulWidget {
  final NoteModel note;
  final String projectID;
  final String canvasID;
  final double canvasWidth;
  final bool isEditable;

  const DraggableNoteWidget({
    super.key,
    required this.note,
    required this.projectID,
    required this.canvasID,
    required this.canvasWidth,
    this.isEditable = true,
  });

  @override
  ConsumerState<DraggableNoteWidget> createState() =>
      _DraggableNoteWidgetState();
}

class _DraggableNoteWidgetState extends ConsumerState<DraggableNoteWidget> {
  bool isSelected = false;
  double? localPosX;
  double? localPosY;

  static const Color noteColor = Color(0xFFFFEB3B);

  double get displayX => localPosX ?? widget.note.posX;
  double get displayY => localPosY ?? widget.note.posY;

  void showEditDialog() async {
    final controller = TextEditingController(text: widget.note.text);
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

    if (result != null && result != widget.note.text && mounted) {
      ref.read(projectRepositoryProvider).updateNote(
            projectID: widget.projectID,
            canvasID: widget.canvasID,
            noteID: widget.note.id,
            data: {'text': result},
          );
    }
  }

  void confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note', style: AppStyles.h3(context)),
        content: Text(
          'Delete "${widget.note.text}"?',
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
      ref.read(projectRepositoryProvider).deleteNote(
            projectID: widget.projectID,
            canvasID: widget.canvasID,
            noteID: widget.note.id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: displayX * widget.canvasWidth,
      top: displayY * widget.canvasWidth,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          onTap: () => setState(() => isSelected = !isSelected),
          onPanUpdate: isSelected && widget.isEditable
              ? (details) {
                  setState(() {
                    localPosX = ((localPosX ?? widget.note.posX) *
                                widget.canvasWidth +
                            details.delta.dx) /
                        widget.canvasWidth;
                    localPosY = ((localPosY ?? widget.note.posY) *
                                widget.canvasWidth +
                            details.delta.dy) /
                        widget.canvasWidth;
                    localPosX = localPosX!.clamp(0.0, 1.0);
                    localPosY = localPosY!.clamp(0.0, 5.0);
                  });
                }
              : null,
          onPanEnd: isSelected && widget.isEditable
              ? (_) {
                  if (localPosX != null && localPosY != null) {
                    ref.read(projectRepositoryProvider).updateNote(
                          projectID: widget.projectID,
                          canvasID: widget.canvasID,
                          noteID: widget.note.id,
                          data: {'posX': localPosX, 'posY': localPosY},
                        );
                    localPosX = null;
                    localPosY = null;
                  }
                }
              : null,
          behavior: isSelected
              ? HitTestBehavior.opaque
              : HitTestBehavior.deferToChild,
          child: isSelected ? buildSelectedState() : buildIdleState(),
        ),
      ),
    );
  }

  Widget buildIdleState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: noteColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        widget.note.text,
        style: const TextStyle(fontSize: 12, color: AppStyles.grey900),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget buildSelectedState() {
    return Container(
      constraints: const BoxConstraints(minWidth: 60, maxWidth: 120),
      decoration: BoxDecoration(
        border: Border.all(color: noteColor, width: 2),
        borderRadius: BorderRadius.circular(6),
        color: noteColor.withValues(alpha: 0.15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_indicator,
                    size: 16, color: AppStyles.grey600),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => isSelected = false),
                  child:
                      const Icon(Icons.close, size: 16, color: AppStyles.grey600),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              widget.note.text,
              style: const TextStyle(fontSize: 12, color: AppStyles.grey900),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (widget.isEditable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: showEditDialog,
                    child: const Icon(Icons.edit,
                        size: 16, color: AppStyles.darkNavy),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: confirmDelete,
                    child: const Icon(Icons.delete,
                        size: 16, color: AppStyles.error),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

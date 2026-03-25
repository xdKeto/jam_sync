import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class CanvasOptionSheet extends ConsumerStatefulWidget {
  final List<CanvasModel> canvases;
  final CanvasModel? selectedCanvas;
  final ValueChanged<CanvasModel> onCanvasSelected;

  const CanvasOptionSheet({
    super.key,
    required this.canvases,
    this.selectedCanvas,
    required this.onCanvasSelected,
  });

  @override
  ConsumerState<CanvasOptionSheet> createState() => _CanvasOptionSheetState();
}

class _CanvasOptionSheetState extends ConsumerState<CanvasOptionSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pilih Canvas", style: AppStyles.h3(context).copyWith(color: AppStyles.darkNavy)),
          const SizedBox(height: 4),
          ...widget.canvases.map((canvas) {
            final isSelected =
                widget.selectedCanvas?.id == canvas.id ||
                (widget.selectedCanvas == null &&
                    widget.canvases.isNotEmpty &&
                    widget.canvases.first.id == canvas.id);
            return ListTile(
              leading: const Icon(Icons.document_scanner_outlined, color: AppStyles.darkNavy),
              title: Text(
                canvas.title,
                style: AppStyles.bodyMedium(context).copyWith(
                  color: AppStyles.darkNavy,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check, color: AppStyles.darkNavy) : null,
              onTap: () {
                widget.onCanvasSelected(canvas);
                Navigator.pop(context);
              },
            );
          }),
          const Divider(color: AppStyles.grey300),
          ListTile(
            leading: const Icon(Icons.add, color: AppStyles.darkNavy),
            title: Text(
              "Tambah Canvas Baru",
              style: AppStyles.bodyMedium(
                context,
              ).copyWith(color: AppStyles.darkNavy, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              // Nanti implementasi untuk tambah canvas
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

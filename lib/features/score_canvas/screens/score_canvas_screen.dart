import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/canvas_provider.dart';
import 'package:jam_sync/shared/models/canvas_model.dart';
import 'package:jam_sync/features/score_canvas/widgets/canvas_widget.dart';
import 'package:jam_sync/shared/widgets/home_nav.dart';

class ScoreCanvasScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String roomCode;

  const ScoreCanvasScreen({super.key, required this.projectId, required this.roomCode});

  @override
  ConsumerState<ScoreCanvasScreen> createState() => _ScoreCanvasScreenState();
}

class _ScoreCanvasScreenState extends ConsumerState<ScoreCanvasScreen> {
  CanvasModel? _selectedCanvas;

  void _showCanvasSelectionBottomSheet(BuildContext context, List<CanvasModel> canvases) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: AppStyles.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pilih Canvas",
                style: AppStyles.h3(context).copyWith(color: AppStyles.darkNavy),
              ),
              const SizedBox(height: 4),
              ...canvases.map((canvas) {
                final isSelected =
                    _selectedCanvas?.id == canvas.id ||
                    (_selectedCanvas == null &&
                        canvases.isNotEmpty &&
                        canvases.first.id == canvas.id);
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
                    setState(() {
                      _selectedCanvas = canvas;
                    });
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canvasesAsync = ref.watch(canvasesStreamProvider(widget.projectId));
    final canvases = canvasesAsync.value ?? [];

    final currentCanvas = _selectedCanvas ?? (canvases.isNotEmpty ? canvases.first : null);
    final titleToDisplay = currentCanvas?.title ?? "Score Canvas";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.darkNavy,
        elevation: 8,
        scrolledUnderElevation: 8,
        leading: IconButton(
          icon: const Icon(Icons.home, color: AppStyles.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeNav()),
              (route) => false,
            );
          },
        ),
        title: GestureDetector(
          onTap: () {
            _showCanvasSelectionBottomSheet(context, canvases);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left, color: AppStyles.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  titleToDisplay,
                  style: AppStyles.h3(context).copyWith(color: AppStyles.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppStyles.white),
            ],
          ),
        ),
        centerTitle: true,
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8),
        actions: [
          Material(
            color: AppStyles.mediumBlue,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () {
                debugPrint("test");
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.group, color: AppStyles.white),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppStyles.white,
      body: SafeArea(
        child: canvasesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          data: (canvases) {
            if (currentCanvas == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.music_square, size: 64, color: AppStyles.grey400),
                    const SizedBox(height: 16),
                    Text(
                      'Empty Canvas, create new section!',
                      style: AppStyles.h3(context).copyWith(color: AppStyles.grey400),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CanvasWidget(
                    projectId: widget.projectId,
                    canvasId: currentCanvas.id,
                    timeSignature: currentCanvas.timeSignature,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppStyles.darkNavy,
        child: Row(children: [
        
        ],),
      ),
    );
  }
}

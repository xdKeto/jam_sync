import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/utils/song_templates.dart';
import 'package:jam_sync/shared/widgets/background_gradient.dart';
import 'package:jam_sync/shared/widgets/template_chip.dart';
import 'package:jam_sync/shared/widgets/tempo_picker.dart';
import 'package:jam_sync/shared/widgets/the_button.dart';
import 'package:quickalert/quickalert.dart';

class AddCanvasSheet extends ConsumerStatefulWidget {
  final String projectID;
  final List<dynamic> existingCanvases;
  final ValueChanged<dynamic> onCanvasCreated;

  const AddCanvasSheet({
    super.key,
    required this.projectID,
    required this.existingCanvases,
    required this.onCanvasCreated,
  });

  @override
  ConsumerState<AddCanvasSheet> createState() => _AddCanvasSheetState();
}

class _AddCanvasSheetState extends ConsumerState<AddCanvasSheet> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  double tempoValue = 120.0;
  final timeSigController = TextEditingController(text: '4/4');
  bool? useTemplate = true;
  bool isLoading = false;
  Map<String, dynamic>? selectedTemplate;

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      selectedTemplate = template;
      final canvas = template['canvas'] as Map<String, dynamic>;
      tempoValue = (canvas['tempo'] as num?)?.toDouble() ?? 120.0;
      if (titleController.text.isEmpty) {
        titleController.text = template['name'] as String? ?? '';
      }
      useTemplate = true;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    timeSigController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateCanvas() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final repository = ref.read(projectRepositoryProvider);
      final newCanvas = await repository.createCanvas(
        projectID: widget.projectID,
        title: titleController.text.trim(),
        tempo: tempoValue,
        timeSignature: timeSigController.text,
        songTemplate: useTemplate == true ? selectedTemplate : null,
      );

      if (!mounted) return;

      widget.onCanvasCreated(newCanvas);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Gagal membuat canvas: $e',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BackgroundGradient(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppStyles.grey400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Text("New Sheet", style: AppStyles.h3(context).copyWith(color: AppStyles.darkNavy)),
                Divider(color: AppStyles.darkNavy, thickness: 1),
                12.height,
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      RepaintBoundary(
                        child: Container(
                          decoration: AppStyles.whiteBox(),
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Song Title", style: AppStyles.h5(context)),
                              4.height,
                              TextFormField(
                                controller: titleController,
                                cursorColor: AppStyles.black,
                                decoration: AppStyles.formBox.copyWith(
                                  hintText: 'Song Title',
                                  hintStyle: AppStyles.bodyMedium(
                                    context,
                                  ).copyWith(color: AppStyles.grey500),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppStyles.darkNavy),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a song title';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      12.height,
                      TempoPicker(
                        value: tempoValue,
                        onChanged: (value) {
                          setState(() {
                            tempoValue = value;
                          });
                        },
                      ),
                      12.height,
                      RepaintBoundary(
                        child: Container(
                          decoration: AppStyles.whiteBox(),
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Time Signature", style: AppStyles.h5(context)),
                              4.height,
                              DropdownButtonFormField<String>(
                                initialValue: timeSigController.text.isNotEmpty
                                    ? timeSigController.text
                                    : '4/4',
                                dropdownColor: Colors.white,
                                decoration: AppStyles.formBox.copyWith(
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppStyles.darkNavy),
                                  ),
                                ),
                                items: ['4/4', '3/4', '2/4', '6/8']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e, style: AppStyles.bodyMedium(context)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      timeSigController.text = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      12.height,
                      RepaintBoundary(
                        child: Container(
                          decoration: AppStyles.whiteBox(),
                          padding: EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Use default template", style: AppStyles.h5(context)),
                              Switch(
                                value: useTemplate ?? true,
                                activeThumbColor: AppStyles.darkNavy,
                                onChanged: (value) {
                                  setState(() {
                                    useTemplate = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      12.height,
                      if (useTemplate == true)
                        RepaintBoundary(
                          child: Container(
                            decoration: AppStyles.whiteBox(),
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text("Song Template", style: AppStyles.h5(context)),
                                    if (selectedTemplate != null) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedTemplate = null;
                                            titleController.text = '';
                                            tempoValue = 120.0;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppStyles.darkNavy,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            "Clear",
                                            style: AppStyles.labelSmall(
                                              context,
                                            ).copyWith(color: AppStyles.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                8.height,
                                Text(
                                  "Pilih lagu di bawah untuk auto-fill tempo & nama",
                                  style: AppStyles.labelSmall(context),
                                ),
                                8.height,
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final template in songTemplates)
                                      TemplateChip(
                                        template: template,
                                        isSelected: selectedTemplate?['id'] == template['id'],
                                        onTap: () => _applyTemplate(template),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                16.height,
                GestureDetector(
                  onTap: isLoading ? null : _handleCreateCanvas,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppStyles.darkNavy))
                      : TheButton(
                          text: "Tambah Partitur",
                          color: AppStyles.darkNavy,
                          textColor: AppStyles.white,
                          vertPadding: 12,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}


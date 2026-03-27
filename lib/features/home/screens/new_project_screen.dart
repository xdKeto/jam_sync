import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/features/home/providers/create_project_provider.dart';
import 'package:jam_sync/features/score_canvas/providers/room_provider.dart';
import 'package:jam_sync/features/score_canvas/screens/score_canvas_screen.dart';
import 'package:jam_sync/shared/repositories/project_repository.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/background_gradient.dart';
import 'package:jam_sync/shared/widgets/the_button.dart';
import 'package:quickalert/quickalert.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class NewProjectScreen extends ConsumerStatefulWidget {
  const NewProjectScreen({super.key});

  @override
  ConsumerState<NewProjectScreen> createState() => NewProjectScreenState();
}

class NewProjectScreenState extends ConsumerState<NewProjectScreen> {
  final formKey = GlobalKey<FormState>();
  final projectTitleController = TextEditingController();
  final defaultSongTitleController = TextEditingController();
  double tempoValue = 120.0;
  final projectTimeSigController = TextEditingController(text: '4/4');
  bool? useSongTemplate = true;
  bool isLoading = false;

  @override
  void dispose() {
    projectTitleController.dispose();
    defaultSongTitleController.dispose();
    projectTimeSigController.dispose();
    super.dispose();
  }

  Future<void> handleCreateProject() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final success = await ref
        .read(createProjectProvider.notifier)
        .createProject(
          title: projectTitleController.text.trim(),
          songTitle: defaultSongTitleController.text.trim(),
          tempo: tempoValue,
          timeSignature: projectTimeSigController.text,
          useTemplate: useSongTemplate ?? true,
        );

    if (!mounted) return;

    if (success) {
      final projectId = ref.read(createProjectProvider).createdProjectId!;
      final project = await ref.read(projectRepositoryProvider).getProject(projectId);
      final userId = ref.read(authNotifierProvider.notifier).getCurrentUser()!.uid;

      await ref
          .read(roomProvider.notifier)
          .createAndJoinRoom(projectID: projectId, roomCode: project.roomCode, userID: userId);

      if (!mounted) return;
      setState(() => isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScoreCanvasScreen(projectID: projectId, roomCode: project.roomCode),
        ),
      );
    } else {
      setState(() => isLoading = false);
      final error = ref.read(createProjectProvider).error;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: error ?? 'Failed to create project',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundGradient(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: Colors.transparent,
          title: Text("New Project", style: AppStyles.h2(context)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppStyles.backgroundDark, height: 1),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              // horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: isLoading ? null : handleCreateProject,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppStyles.darkNavy))
                      : TheButton(
                          text: "Create Project",
                          color: AppStyles.darkNavy,
                          textColor: AppStyles.white,
                          vertPadding: 12,
                        ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: ListView(
                children: [
                  // Divider(color: AppStyles.backgroundDark, thickness: 1),
                  4.height,
                  Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RepaintBoundary(
                          child: Container(
                            decoration: AppStyles.whiteBox(),
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Project Title", style: AppStyles.h5(context)),
                                4.height,
                                TextFormField(
                                  cursorColor: AppStyles.black,
                                  decoration: AppStyles.formBox.copyWith(
                                    hintText: 'Project Title',
                                    hintStyle: AppStyles.bodyMedium(
                                      context,
                                    ).copyWith(color: AppStyles.grey500),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: AppStyles.darkNavy),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a project title';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) => projectTitleController.text = value,
                                ),
                              ],
                            ),
                          ),
                        ),
                        12.height,
                        Text("Default Canvas Setting", style: AppStyles.h4(context)),
                        Divider(color: AppStyles.darkNavy, thickness: 1),
                        4.height,
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
                                      return 'Please enter a project title';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) => defaultSongTitleController.text = value,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text("Tempo (BPM)", style: AppStyles.h5(context)),
                                    Text(
                                      " - nilai ini bisa diubah nanti",
                                      style: AppStyles.labelSmall(context),
                                    ),
                                  ],
                                ),
                                12.height,
                                Row(
                                  children: [
                                    Expanded(
                                      child: SfSlider(
                                        min: 40.0,
                                        max: 200.0,
                                        value: tempoValue,
                                        interval: 40,
                                        stepSize: 1.0,
                                        showTicks: true,
                                        showLabels: true,
                                        enableTooltip: true,
                                        minorTicksPerInterval: 3,
                                        activeColor: AppStyles.darkNavy,
                                        tooltipTextFormatterCallback:
                                            (dynamic actualValue, String formattedText) {
                                              return (actualValue as double).round().toString();
                                            },
                                        labelFormatterCallback:
                                            (dynamic actualValue, String formattedText) {
                                              return (actualValue as double).round().toString();
                                            },
                                        onChanged: (dynamic value) {
                                          setState(() {
                                            tempoValue = (value as double).roundToDouble();
                                          });
                                        },
                                      ),
                                    ),
                                    8.width,
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.arrow_drop_up, size: 32),
                                          onPressed: () {
                                            if (tempoValue < 200.0) {
                                              setState(() {
                                                tempoValue += 1.0;
                                              });
                                            }
                                          },
                                        ),
                                        Text(
                                          tempoValue.round().toString(),
                                          style: AppStyles.h3(context),
                                        ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.arrow_drop_down, size: 32),
                                          onPressed: () {
                                            if (tempoValue > 40.0) {
                                              setState(() {
                                                tempoValue -= 1.0;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    16.width,
                                  ],
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Time Signature", style: AppStyles.h5(context)),
                                4.height,
                                DropdownButtonFormField<String>(
                                  initialValue: projectTimeSigController.text.isNotEmpty
                                      ? projectTimeSigController.text
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
                                        projectTimeSigController.text = value;
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
                                  value: useSongTemplate ?? true,
                                  activeThumbColor: AppStyles.darkNavy,
                                  onChanged: (value) {
                                    setState(() {
                                      useSongTemplate = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

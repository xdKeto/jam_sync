import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/background_gradient.dart';

class NewProjectScreen extends ConsumerStatefulWidget {
  const NewProjectScreen({super.key});

  @override
  ConsumerState<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends ConsumerState<NewProjectScreen> {
  final formKey = GlobalKey<FormState>();
  final projectTitleController = TextEditingController();
  final projectTempoController = TextEditingController();
  final projectTimeSigController = TextEditingController();
  bool? useSongTemplate = true;

  @override
  void dispose() {
    projectTitleController.dispose();
    projectTempoController.dispose();
    projectTimeSigController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: Column(
                children: [
                  Text("New Project", style: AppStyles.h2(context)),
                  12.height,
                  Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextFormField(
                          cursorColor: AppStyles.black,
                          decoration: AppStyles.formBox.copyWith(
                            hintText: 'Project Title',
                            hintStyle: AppStyles.bodyMedium(
                              context,
                            ).copyWith(color: AppStyles.grey500),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a project title';
                            }
                            return null;
                          },
                          onChanged: (value) =>
                              projectTitleController.text = value,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/features/auth/widgets/avatar_picker.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/loading_screen.dart';
import 'package:jam_sync/shared/widgets/the_button.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedAvatar;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an avatar'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingScreen(),
    );
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .saveUser(
            displayName: _nameController.text,
            photoURL: _selectedAvatar,
          );

      ref.invalidate(isNewUserProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save user'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.lightTeal,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Welcome, complete your profile!",
                  style: AppStyles.bodyLarge(context),
                  textAlign: TextAlign.center,
                ),
                24.height,
                GestureDetector(
                  onTap: () async {
                    final result = await showModalBottomSheet<String>(
                      context: context,
                      enableDrag: false,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          AvatarPicker(initialAvatar: _selectedAvatar),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedAvatar = result;
                      });
                    }
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 64,
                        // backgroundColor: AppStyles.darkNavy,
                        backgroundImage: AssetImage(
                          _selectedAvatar ??
                              'assets/images/avatar-placeholder.jpg',
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppStyles.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            color: AppStyles.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                16.height,
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 420,
                        child: TextFormField(
                          cursorColor: AppStyles.black,
                          decoration: AppStyles.formBox.copyWith(
                            hintText: 'Name',
                            hintStyle: AppStyles.bodyMedium(
                              context,
                            ).copyWith(color: AppStyles.grey500),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                          onChanged: (value) => _nameController.text = value,
                        ),
                      ),
                    ],
                  ),
                ),
                16.height,
                GestureDetector(
                  onTap: submitForm,
                  child: TheButton(
                    text: "Continue",
                    color: AppStyles.darkNavy,
                    textColor: AppStyles.white,
                    hoverable: false,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/home/providers/join_room_provider.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/widgets/background_gradient.dart';
import 'package:jam_sync/shared/widgets/the_button.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final formKey = GlobalKey<FormState>();
  final roomCodeController = TextEditingController();

  @override
  void dispose() {
    roomCodeController.dispose();
    super.dispose();
  }

  Future<void> handleJoinRoom() async {
    if (!formKey.currentState!.validate()) return;

    final success = await ref
        .read(joinRoomProvider.notifier)
        .joinRoom(roomCodeController.text);

    if (!mounted) return;

    if (success) {
      ref.read(joinRoomProvider.notifier).reset();
      Navigator.of(context).pop(true);
    } else {
      final error = ref.read(joinRoomProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to join room'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(joinRoomProvider).isLoading;

    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: Colors.transparent,
          title: Text("Join Room", style: AppStyles.h2(context)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppStyles.backgroundDark, height: 1),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: isLoading ? null : handleJoinRoom,
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppStyles.darkNavy,
                          ),
                        )
                      : TheButton(
                          text: "Join Room",
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: ListView(
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: AppStyles.whiteBox(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Enter Room Code",
                                style: AppStyles.h4(context),
                              ),
                              8.height,
                              Text(
                                "Ask your friend for the room code to join their project.",
                                style: AppStyles.bodyMedium(
                                  context,
                                ).copyWith(color: AppStyles.grey600),
                              ),
                              16.height,
                              TextFormField(
                                controller: roomCodeController,
                                cursorColor: AppStyles.black,
                                keyboardType: TextInputType.number,
                                decoration: AppStyles.formBox.copyWith(
                                  hintText: 'e.g., 123456',
                                  hintStyle: AppStyles.bodyMedium(
                                    context,
                                  ).copyWith(color: AppStyles.grey500),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppStyles.darkNavy,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a room code';
                                  }
                                  return null;
                                },
                              ),
                            ],
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

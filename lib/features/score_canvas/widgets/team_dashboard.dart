import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/score_canvas/providers/participants_provider.dart';
import 'package:jam_sync/features/score_canvas/providers/room_provider.dart';
import 'package:jam_sync/features/score_canvas/widgets/participant_tile.dart';
import 'package:jam_sync/shared/models/participant_info_model.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/widgets/background_gradient.dart';
import 'package:jam_sync/shared/widgets/the_button.dart';

class TeamDashboard extends ConsumerStatefulWidget {
  final String projectId;

  const TeamDashboard({super.key, required this.projectId});

  @override
  ConsumerState<TeamDashboard> createState() => _TeamDashboardState();
}

class _TeamDashboardState extends ConsumerState<TeamDashboard> {
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(roomProvider).isLoading;

    final roomState = ref.watch(roomProvider);
    final participantsAsync = ref.watch(participantsStreamProvider(widget.projectId));

    final isLeader = participantsAsync.value?.any((p) => p.isLeader) ?? false;

    return BackgroundGradient(
      usePadding: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppStyles.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Team Dashboard", style: AppStyles.h3(context).copyWith(color: AppStyles.white)),
              Text(
                "Room Code: ${roomState.roomCode ?? '-'}",
                style: AppStyles.bodySmall(context).copyWith(color: AppStyles.lightTeal),
              ),
            ],
          ),
          toolbarHeight: 80,
          backgroundColor: AppStyles.darkNavy,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: isLoading ? null : () => debugPrint('test'),
                  child: isLoading
                      ? Center(child: CircularProgressIndicator(color: AppStyles.darkNavy))
                      : TheButton(
                          text: isLeader ? "Start Jamming" : "Ready Up",
                          color: AppStyles.darkNavy,
                          textColor: AppStyles.white,
                          vertPadding: 12,
                        ),
                ),
              ],
            ),
          ),
        ),
        body: participantsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
          ),
          data: (participants) {
            if (participants.isEmpty) {
              return Center(
                child: Text(
                  'No participants yet',
                  style: AppStyles.bodyMedium(context).copyWith(color: AppStyles.white),
                ),
              );
            }

            final sorted = List<ParticipantInfo>.from(participants)
              ..sort((a, b) {
                if (a.isLeader) return -1;
                if (b.isLeader) return 1;
                if (a.isOnline && !b.isOnline) return -1;
                if (!a.isOnline && b.isOnline) return 1;
                return a.displayName.compareTo(b.displayName);
              });

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: AppStyles.whiteBox(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return ParticipantTile(participant: sorted[index]);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

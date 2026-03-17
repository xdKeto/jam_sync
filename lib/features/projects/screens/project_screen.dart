import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/home/providers/projects_provider.dart';
import 'package:jam_sync/features/home/widgets/project_card.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
import 'package:jam_sync/shared/utils/time_ago_helper.dart';
import 'package:jam_sync/shared/widgets/background_gradient.dart';

class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsetsGeometry.all(8),
            child: Column(
              children: [
                16.height,
                Text("Your Projects", style: AppStyles.h2(context)),
                12.height,
                Expanded(
                  child: ref
                      .watch(projectsProvider)
                      .when(
                        data: (projects) {
                          return RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(projectsProvider);
                            },
                            child: projects.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.4,
                                        child: Center(
                                          child: Text(
                                            "No projects yet.",
                                            style: AppStyles.bodyLarge(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: projects.length,
                                    itemBuilder: (context, index) {
                                      final p = projects[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: ProjectCard(
                                          title: p.title,
                                          creatorId: p.createdBy,
                                          roomCode: p.roomCode,
                                          timeAgo: timeAgoFromDate(
                                            p.createdAt ?? DateTime.now(),
                                          ),
                                          participants: p.participants,
                                        ),
                                      );
                                    },
                                  ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(child: Text('Error: $e')),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/home/widgets/project_card.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/shared/utils/gap_helper.dart';
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
                ...List.generate(3, (index) {
                  final projects = [
                    {
                      'title': 'Summer Vibes Jam',
                      'bpm': 120,
                      'ts': '4/4',
                      'time': '2 hours ago',
                    },
                    {
                      'title': 'Chill Lofi Beat',
                      'bpm': 85,
                      'ts': '4/4',
                      'time': '5 hours ago',
                    },
                    {
                      'title': 'Rock Anthem Draft',
                      'bpm': 140,
                      'ts': '3/4',
                      'time': '1 day ago',
                    },
                  ];
                  final p = projects[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ProjectCard(
                      title: p['title'] as String,
                      bpm: p['bpm'] as int,
                      timeSignature: p['ts'] as String,
                      timeAgo: p['time'] as String,
                      participantAvatarUrls: [],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

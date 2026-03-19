import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';
import 'package:jam_sync/features/score_canvas/widgets/canvas_widget.dart';
import 'package:jam_sync/shared/widgets/home_nav.dart';

class ScoreCanvasScreen extends StatefulWidget {
  const ScoreCanvasScreen({super.key});

  @override
  State<ScoreCanvasScreen> createState() => _ScoreCanvasScreenState();
}

class _ScoreCanvasScreenState extends State<ScoreCanvasScreen> {
  @override
  Widget build(BuildContext context) {
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
            // TODO: show bottom sheet to select canvas
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left, color: AppStyles.white),
              const SizedBox(width: 8),
              Text("Score Canvas", style: AppStyles.h3(context).copyWith(color: AppStyles.white)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppStyles.white),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.group, color: AppStyles.white),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: AppStyles.white,
      body: const SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: CanvasWidget())],
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

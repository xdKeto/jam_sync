import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:jam_sync/features/home/screens/home_screen.dart';
import 'package:jam_sync/features/home/screens/new_project_screen.dart';
import 'package:jam_sync/features/projects/screens/project_screen.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  var _bottomNavIndex = 0;

  final iconList = <IconData>[Iconsax.home_1, Iconsax.music_library_2];

  final activeIconList = <IconData>[Iconsax.home_2, Iconsax.music_library_2];

  final List<Widget> _screens = [const HomeScreen(), const ProjectScreen()];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBody: true,
        body: _screens[_bottomNavIndex],
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          elevation: 3,
          backgroundColor: AppStyles.black,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewProjectScreen(),
              ),
            );
          },
          child: const Icon(Icons.add, color: AppStyles.white, size: 32),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AnimatedBottomNavigationBar.builder(
          itemCount: iconList.length,
          tabBuilder: (int index, bool isActive) {
            final color = isActive ? AppStyles.black : AppStyles.grey600;
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? activeIconList[index] : iconList[index],
                  size: 24,
                  color: color,
                ),
                const SizedBox(height: 2),
                Text(
                  index == 0 ? "Home" : "Projects",
                  style: TextStyle(
                    color: color,
                    fontSize: isActive ? 12 : 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          },
          backgroundColor: Colors.white,
          activeIndex: _bottomNavIndex,
          splashColor: AppStyles.skyBlue.withValues(alpha: 0.2),
          splashSpeedInMilliseconds: 200,
          scaleFactor: 0.2,
          splashRadius: 50,
          height: 65,
          notchSmoothness: NotchSmoothness.softEdge,
          gapLocation: GapLocation.center,
          leftCornerRadius: 32,
          rightCornerRadius: 32,
          onTap: (index) => setState(() => _bottomNavIndex = index),
          // shadow: const BoxShadow(
          //   // offset: Offset(0, 1),
          //   blurRadius: 12,
          //   spreadRadius: 0.5,
          //   color: AppStyles.black,
          // ),
          elevation: 20,
          shadow: BoxShadow(
            offset: Offset(0, 1),
            blurRadius: 8,
            // blurStyle: BlurStyle.outer,
            color: AppStyles.grey600,
          ),
        ),
      ),
    );
  }
}

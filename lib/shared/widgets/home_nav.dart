import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:jam_sync/features/projects/screens/home_screen.dart';
import 'package:jam_sync/features/profile/screens/profile_screen.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  var _bottomNavIndex = 0;

  final iconList = <IconData>[Icons.home_outlined, Icons.person_outline];

  final activeIconList = <IconData>[Icons.home, Icons.person];

  final List<Widget> _screens = [const HomeScreen(), const ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_bottomNavIndex],
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        elevation: 3,
        backgroundColor: Colors.white,
        onPressed: () {
          // TODO: Implement add project
        },
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: iconList.length,
        tabBuilder: (int index, bool isActive) {
          final color = isActive ? Colors.black : Colors.grey;
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
                index == 0 ? "Home" : "Profile",
                style: TextStyle(
                  color: color,
                  fontSize: 10,
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
    );
  }
}

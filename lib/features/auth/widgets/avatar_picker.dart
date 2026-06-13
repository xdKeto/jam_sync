import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class AvatarPicker extends StatefulWidget {
  final String? initialAvatar;

  const AvatarPicker({super.key, this.initialAvatar});

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  String? selectedAvatar;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    selectedAvatar = widget.initialAvatar;
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppStyles.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          buildHeader(),
          buildTabBar(),
          Expanded(child: buildTabBarView()),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppStyles.bodyMedium(
                context,
              ).copyWith(color: AppStyles.grey500),
            ),
          ),
          Text(
            'Choose Avatar',
            style: AppStyles.bodyLarge(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: selectedAvatar != null
                ? () => Navigator.pop(context, selectedAvatar)
                : null,
            child: Text(
              'Done',
              style: AppStyles.bodyMedium(context).copyWith(
                color: selectedAvatar != null
                    ? AppStyles.darkNavy
                    : AppStyles.grey500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabBar() {
    return TabBar(
      controller: tabController,
      labelColor: AppStyles.darkNavy,
      unselectedLabelColor: AppStyles.grey500,
      indicatorColor: AppStyles.darkNavy,
      tabs: const [
        Tab(icon: Icon(Icons.male)),
        Tab(icon: Icon(Icons.female)),
      ],
    );
  }

  Widget buildTabBarView() {
    return TabBarView(
      controller: tabController,
      children: [
        buildAvatarGrid('boy', 1, 50),
        buildAvatarGrid('girl', 51, 100),
      ],
    );
  }

  Widget buildAvatarGrid(String folder, int startIndex, int endIndex) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: endIndex - startIndex + 1,
      itemBuilder: (context, index) {
        final avatarIndex = startIndex + index;
        final avatarPath = 'assets/avatars/$folder/AV$avatarIndex.png';
        final isSelected = selectedAvatar == avatarPath;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedAvatar = avatarPath;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppStyles.darkNavy, width: 5)
                  : null,
            ),
            child: ClipOval(
              child: Image.asset(
                avatarPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppStyles.grey200,
                    child: Icon(Icons.person, color: AppStyles.grey500),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

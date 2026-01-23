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
  late TabController _tabController;
  String? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedAvatar = widget.initialAvatar;
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          _buildHeader(),
          _buildTabBar(),
          Expanded(child: _buildTabBarView()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
            onPressed: _selectedAvatar != null
                ? () => Navigator.pop(context, _selectedAvatar)
                : null,
            child: Text(
              'Done',
              style: AppStyles.bodyMedium(context).copyWith(
                color: _selectedAvatar != null
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

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppStyles.darkNavy,
      unselectedLabelColor: AppStyles.grey500,
      indicatorColor: AppStyles.darkNavy,
      tabs: const [
        Tab(icon: Icon(Icons.male)),
        Tab(icon: Icon(Icons.female)),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAvatarGrid('boy', 1, 50),
        _buildAvatarGrid('girl', 51, 100),
      ],
    );
  }

  Widget _buildAvatarGrid(String folder, int startIndex, int endIndex) {
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
        final isSelected = _selectedAvatar == avatarPath;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAvatar = avatarPath;
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

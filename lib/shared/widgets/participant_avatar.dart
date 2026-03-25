import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jam_sync/features/auth/providers/auth_provider.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class ParticipantAvatar extends ConsumerWidget {
  final String uid;
  final double size;

  const ParticipantAvatar({super.key, required this.uid, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userProvider(uid));

    return userData.when(
      data: (data) {
        final url = data?['photoURL'] as String? ?? '';
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppStyles.white, width: 2),
            color: AppStyles.grey300,
          ),
          child: ClipOval(
            child: url.isNotEmpty
                ? Image(
                    image: url.startsWith('assets/')
                        ? AssetImage(url) as ImageProvider
                        : NetworkImage(url),
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, size: 14, color: Colors.white),
                  )
                : const Icon(Icons.person, size: 14, color: Colors.white),
          ),
        );
      },
      loading: () => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppStyles.white, width: 2),
          color: AppStyles.grey300,
        ),
      ),
      error: (error, stackTrace) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppStyles.white, width: 2),
          color: AppStyles.grey300,
        ),
        child: const Icon(Icons.error_outline, size: 14, color: Colors.white),
      ),
    );
  }
}

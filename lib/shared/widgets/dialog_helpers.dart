import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmText = 'Delete',
  String cancelText = 'Cancel',
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: AppStyles.h3(context)),
      content: Text(content, style: AppStyles.bodyMedium(context)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDestructive ? Colors.red : null,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> showDeleteDialog(
  BuildContext context, {
  required String title,
  required String content,
}) async {
  return showConfirmDialog(
    context,
    title: title,
    content: content,
    confirmText: 'Delete',
    cancelText: 'Cancel',
    isDestructive: true,
  );
}

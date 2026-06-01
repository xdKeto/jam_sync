import 'package:flutter/material.dart';
import 'package:jam_sync/shared/utils/app_styles.dart';

class TemplateChip extends StatelessWidget {
  final Map<String, dynamic> template;
  final bool isSelected;
  final VoidCallback onTap;

  const TemplateChip({super.key, required this.template, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final canvas = template['canvas'] as Map<String, dynamic>;
    final name = template['name'] as String;
    final tempo = canvas['tempo'] as int?;

    return Material(
      color: isSelected ? AppStyles.darkNavy : AppStyles.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppStyles.darkNavy : AppStyles.grey400,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppStyles.bodySmall(context).copyWith(
                      color: isSelected ? AppStyles.white : AppStyles.darkNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (tempo != null)
                    Text(
                      '♩ $tempo BPM',
                      style: AppStyles.labelSmall(context).copyWith(
                        color: isSelected
                            ? AppStyles.white.withValues(alpha: 0.7)
                            : AppStyles.grey500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

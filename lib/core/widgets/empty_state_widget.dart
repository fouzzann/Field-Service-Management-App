import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/text_styles.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 64),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

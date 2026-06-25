import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/text_styles.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.title.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              )
            ]
          ],
        ),
      ),
    );
  }
}

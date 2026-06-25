import 'package:flutter/material.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/text_styles.dart';
import '../../../../injection_container.dart' as di;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text('Data Management', style: AppTextStyles.title),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
            title: const Text('Clear Local Database Cache'),
            subtitle: const Text('Deletes all cached tasks, sync queue, and user sessions from Hive'),
            trailing: const Icon(Icons.chevron_right),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Local Cache?'),
                  content: const Text('This will log you out and delete all local tasks and pending actions. This action is irreversible.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final hiveService = di.sl<HiveService>();
                await hiveService.clearAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared successfully.')),
                  );
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
          ),
          const SizedBox(height: 32),
          Text('App Information', style: AppTextStyles.title),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.primaryLight),
            title: const Text('Field Service Management App'),
            subtitle: const Text('Version 1.0.0+1 (Clean Architecture & BLoC)'),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

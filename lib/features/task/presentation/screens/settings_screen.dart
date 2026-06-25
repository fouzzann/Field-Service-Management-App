import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:field_service_management_app/core/services/hive_service.dart';
import 'package:field_service_management_app/core/utils/app_colors.dart';
import 'package:field_service_management_app/core/utils/text_styles.dart';
import 'package:field_service_management_app/injection_container.dart' as di;
import 'package:field_service_management_app/features/task/presentation/bloc/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, currentThemeMode) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text('Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text('Theme Settings', style: AppTextStyles.title),
              const SizedBox(height: 16),
              
              // Premium Segmented Choice Cards
              Row(
                children: [
                  _buildThemeOption(
                    context,
                    title: 'System',
                    icon: Icons.brightness_auto_outlined,
                    mode: ThemeMode.system,
                    currentMode: currentThemeMode,
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  _buildThemeOption(
                    context,
                    title: 'Light',
                    icon: Icons.light_mode_outlined,
                    mode: ThemeMode.light,
                    currentMode: currentThemeMode,
                    activeColor: Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  _buildThemeOption(
                    context,
                    title: 'Dark',
                    icon: Icons.dark_mode_outlined,
                    mode: ThemeMode.dark,
                    currentMode: currentThemeMode,
                    activeColor: AppColors.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 36),
              
              Text('Data Management', style: AppTextStyles.title),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.surfaceLight.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
                    ),
                    title: Text(
                      'Clear Local Database Cache',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Deletes all cached tasks, sync queue, and user sessions from Hive',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All Local Cache?'),
                          content: const Text(
                              'This will log you out and delete all local tasks and pending actions. This action is irreversible.'),
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
                ),
              ),
              const SizedBox(height: 36),
              
              Text('App Information', style: AppTextStyles.title),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.surfaceLight.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.info_outline, color: AppColors.primary),
                    ),
                    title: Text(
                      'Field Service Management App',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Version 1.0.0+1 (Clean Architecture & BLoC)',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required Color activeColor,
  }) {
    final isSelected = mode == currentMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<ThemeCubit>().updateTheme(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.surfaceLight.withOpacity(0.4),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: activeColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? activeColor : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/services/hive_service.dart';
import '../cubit/theme_cubit.dart';

class SettingsViewModel extends ChangeNotifier {
  final HiveService hiveService;
  final ThemeCubit themeCubit;

  SettingsViewModel({
    required this.hiveService,
    required this.themeCubit,
  });

  void updateThemeMode(ThemeMode mode) {
    themeCubit.updateTheme(mode);
  }

  Future<void> clearLocalCache() async {
    await hiveService.clearAll();
  }
}

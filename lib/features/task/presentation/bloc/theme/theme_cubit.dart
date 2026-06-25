import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:field_service_management_app/core/services/hive_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final HiveService _hiveService;

  ThemeCubit(this._hiveService) : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    try {
      final themeStr = _hiveService.settingsBox.get('theme_mode', defaultValue: 'system') as String;
      emit(_parseThemeMode(themeStr));
    } catch (_) {
      emit(ThemeMode.system);
    }
  }

  void updateTheme(ThemeMode themeMode) {
    try {
      _hiveService.settingsBox.put('theme_mode', _themeModeToString(themeMode));
    } catch (_) {}
    emit(themeMode);
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}

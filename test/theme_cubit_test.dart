import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_service_management_app/core/services/hive_service.dart';
import 'package:field_service_management_app/features/settings/presentation/cubit/theme_cubit.dart';

class MockHiveService extends Mock implements HiveService {}
class MockBox extends Mock implements Box {}

void main() {
  late MockHiveService mockHiveService;
  late MockBox mockBox;

  setUp(() {
    mockHiveService = MockHiveService();
    mockBox = MockBox();
    when(() => mockHiveService.settingsBox).thenReturn(mockBox);
  });

  group('ThemeCubit', () {
    blocTest<ThemeCubit, ThemeMode>(
      'should load default ThemeMode.system when settings has no value',
      build: () {
        when(() => mockBox.get('theme_mode', defaultValue: 'system')).thenReturn('system');
        return ThemeCubit(mockHiveService);
      },
      expect: () => [],
      verify: (cubit) {
        expect(cubit.state, equals(ThemeMode.system));
      },
    );

    blocTest<ThemeCubit, ThemeMode>(
      'should load ThemeMode.dark when settings has dark',
      build: () {
        when(() => mockBox.get('theme_mode', defaultValue: 'system')).thenReturn('dark');
        return ThemeCubit(mockHiveService);
      },
      expect: () => [],
      verify: (cubit) {
        expect(cubit.state, equals(ThemeMode.dark));
      },
    );

    blocTest<ThemeCubit, ThemeMode>(
      'should emit ThemeMode.light and save to settings box when updateTheme(ThemeMode.light) is called',
      build: () {
        when(() => mockBox.get('theme_mode', defaultValue: 'system')).thenReturn('system');
        when(() => mockBox.put('theme_mode', 'light')).thenAnswer((_) async => {});
        return ThemeCubit(mockHiveService);
      },
      act: (cubit) => cubit.updateTheme(ThemeMode.light),
      expect: () => [ThemeMode.light],
      verify: (_) {
        verify(() => mockBox.put('theme_mode', 'light')).called(1);
      },
    );
  });
}

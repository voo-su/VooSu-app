import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voosu/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('themeLight создаёт светлую тему', () {
      final theme = AppTheme.themeLight();
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, true);
    });

    test('themeDark создаёт тёмную тему', () {
      final theme = AppTheme.themeDark();
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, true);
    });
  });
}

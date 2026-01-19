import 'package:flutter/foundation.dart';
import 'settings_service.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final SettingsService _settingsService = SettingsService();
  final ValueNotifier<bool> themeNotifier = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    await loadTheme();
  }

  Future<void> loadTheme() async {
    final darkMode = await _settingsService.getDarkModeEnabled();
    themeNotifier.value = darkMode;
  }

  Future<void> setDarkMode(bool value) async {
    await _settingsService.setDarkModeEnabled(value);
    themeNotifier.value = value;
  }

  bool get isDarkMode => themeNotifier.value;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storageService);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final dynamic _storageService;

  ThemeModeNotifier(this._storageService)
      : super(_storageService.getIsDarkMode() ? ThemeMode.dark : ThemeMode.light);

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      _storageService.setDarkMode(false);
    } else {
      state = ThemeMode.dark;
      _storageService.setDarkMode(true);
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _storageService.setDarkMode(mode == ThemeMode.dark);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final String language;
  final bool notificationsEnabled;
  final String locationAccuracy;

  const SettingsState({
    this.language = 'English',
    this.notificationsEnabled = true,
    this.locationAccuracy = 'High (GPS + Network)',
  });

  SettingsState copyWith({
    String? language,
    bool? notificationsEnabled,
    String? locationAccuracy,
  }) {
    return SettingsState(
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
    );
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setLanguage(String lang) {
    state = state.copyWith(language: lang);
  }

  void toggleNotifications(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  void setLocationAccuracy(String accuracy) {
    state = state.copyWith(locationAccuracy: accuracy);
  }
}

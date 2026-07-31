import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class StorageService {
  late Box _favoritesBox;
  late Box _recentSearchesBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _favoritesBox = await Hive.openBox(AppConstants.favoritesBox);
    _recentSearchesBox = await Hive.openBox(AppConstants.recentSearchesBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
  }

  // Favorites
  List<String> getFavoriteIds() {
    return _favoritesBox.values.cast<String>().toList();
  }

  Future<void> addFavorite(String id) async {
    await _favoritesBox.put(id, id);
  }

  Future<void> removeFavorite(String id) async {
    await _favoritesBox.delete(id);
  }

  bool isFavorite(String id) {
    return _favoritesBox.containsKey(id);
  }

  // Recent Searches
  List<String> getRecentSearches() {
    return _recentSearchesBox.values.cast<String>().toList();
  }

  Future<void> addRecentSearch(String term) async {
    if (term.trim().isEmpty) return;
    await _recentSearchesBox.put(term, term);
  }

  Future<void> clearRecentSearches() async {
    await _recentSearchesBox.clear();
  }

  // Settings
  bool getIsDarkMode() {
    return _settingsBox.get('dark_mode', defaultValue: true) as bool;
  }

  Future<void> setDarkMode(bool enabled) async {
    await _settingsBox.put('dark_mode', enabled);
  }
}

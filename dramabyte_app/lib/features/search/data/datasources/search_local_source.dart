import 'package:shared_preferences/shared_preferences.dart';

final class SearchLocalSource {
  SearchLocalSource(this._preferences);

  static const _key = 'recent_searches';
  static const maxRecents = 8;
  final SharedPreferences _preferences;

  List<String> recents() => _preferences.getStringList(_key) ?? const [];

  Future<void> save(String query) {
    final term = query.trim();
    if (term.isEmpty) return Future.value();
    final next = [
      term,
      ...recents().where((item) => item.toLowerCase() != term.toLowerCase()),
    ].take(maxRecents).toList();
    return _preferences.setStringList(_key, next);
  }

  Future<void> remove(String query) => _preferences.setStringList(
    _key,
    recents().where((item) => item != query).toList(),
  );

  Future<void> clear() => _preferences.remove(_key);
}

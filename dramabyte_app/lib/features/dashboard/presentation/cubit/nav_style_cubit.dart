import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NavStyle { floating, classic }

class NavStyleCubit extends Cubit<NavStyle> {
  NavStyleCubit() : super(NavStyle.classic) {
    _load();
  }

  static const _key = 'nav_style';
  bool _changed = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (isClosed || _changed) return;
    final saved = prefs.getString(_key);
    emit(
      saved == NavStyle.floating.name ? NavStyle.floating : NavStyle.classic,
    );
  }

  Future<void> setStyle(NavStyle style) async {
    _changed = true;
    emit(style);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, style.name);
  }
}

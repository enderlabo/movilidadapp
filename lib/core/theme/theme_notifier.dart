import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/local_cache.dart';
import '../../injection/injection_container.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';

  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final saved = await sl<LocalCache>().getString(_key);
    if (saved == 'light' && mounted) state = ThemeMode.light;
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    sl<LocalCache>().setString(_key, state == ThemeMode.dark ? 'dark' : 'light');
  }

  bool get isLight => state == ThemeMode.light;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/local_cache.dart';
import '../../injection/injection_container.dart';

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.dark;
  }

  Future<void> _load() async {
    final saved = await sl<LocalCache>().getString(_key);
    if (saved == 'light' && ref.mounted) state = ThemeMode.light;
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    sl<LocalCache>().setString(_key, state == ThemeMode.dark ? 'dark' : 'light');
  }

  bool get isLight => state == ThemeMode.light;
}

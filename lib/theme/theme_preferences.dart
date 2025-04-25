import 'package:economize/theme/app_themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const String themeKey = 'app_theme';

  // Salva o tema escolhido
  Future<void> setTheme(ThemeType theme) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeKey, theme.toString());
  }

  // Recupera o tema salvo (retorna light se não houver tema salvo)
  Future<ThemeType> getTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? themeStr = prefs.getString(themeKey);

    if (themeStr == null) return ThemeType.light;

    return ThemeType.values.firstWhere(
      (theme) => theme.toString() == themeStr,
      orElse: () => ThemeType.light,
    );
  }

  // Verifica se existe um tema salvo
  Future<bool> hasTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(themeKey);
  }

  // Remove o tema salvo (volta para o padrão)
  Future<void> removeTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(themeKey);
  }
}

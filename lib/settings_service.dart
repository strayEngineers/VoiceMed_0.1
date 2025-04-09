import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SettingsService {
  static const String _themeKey = 'theme';
  static const String _languageKey = 'language';
  static const String _fontSizeKey = 'fontSize';

  final _fontSizeController = StreamController<double>.broadcast();
  Stream<double> get fontSizeStream => _fontSizeController.stream;

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(_themeKey) ?? false;
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, theme == ThemeMode.dark);
  }

  Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'zh';
    return Locale(languageCode, languageCode == 'zh' ? 'TW' : '');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }

  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 20.0;
  }

  Future<void> setFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, fontSize);
    _fontSizeController.add(fontSize);
  }

  void dispose() {
    _fontSizeController.close();
  }
}

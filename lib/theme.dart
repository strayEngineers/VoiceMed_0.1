// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, use_build_context_synchronously, library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations, unused_element, use_key_in_widget_constructors, annotate_overrides, avoid_print, use_full_hex_values_for_flutter_colors
import 'package:flutter/material.dart';
import 'settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  final SettingsService _settingsService;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider(this._settingsService) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _loadTheme() async {
    _themeMode = await _settingsService.getThemeMode();
    notifyListeners();
  }

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    _settingsService.setThemeMode(_themeMode);
    notifyListeners();
  }
}

class MyThemes {
  static final lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light().copyWith(
      background: Color(0xffEFF7CF),
      primary: Color(0xFF2A4747),
    ),
    iconTheme: IconThemeData(
      color: Colors.black,
    ),
    dialogBackgroundColor: Color(0xFFEFF7CF),
    dialogTheme: DialogTheme(
      titleTextStyle: TextStyle(
        color: Color(0xFF2A4747),
      ),
      contentTextStyle: TextStyle(
        color: Color(0xFF2A4747),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Color(0xff439775),
      inactiveTrackColor: Color(0xFF439775).withOpacity(0.4),
      thumbColor: Color(0xFFEFF7CF),
      overlayColor: Color(0xFFEFF7CF).withOpacity(0.4),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: Color(0xFF439775),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xffEFF7CF),
        foregroundColor: Color(0xFF2A4747),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Color(0xff439775),
      ),
    ),
  );

  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: Color(0xFF2A4747),
    colorScheme: ColorScheme.dark().copyWith(
      background: Color(0xff439775),
      primary: Color(0xFFEFF7CF),
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
    dialogBackgroundColor: Color(0xFFEFF7CF),
    dialogTheme: DialogTheme(
      titleTextStyle: TextStyle(
        color: Color(0xFF2A4747),
      ),
      contentTextStyle: TextStyle(
        color: Color(0xFF2A4747),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Color(0xFFEFF7CF),
      inactiveTrackColor: Color(0xFFEFF7CF).withOpacity(0.5),
      thumbColor: Color(0xff439775),
      overlayColor: Color(0xFF439775).withOpacity(0.5),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: Color(0xFFEFF7CF),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xff439775),
        foregroundColor: Color(0xFFEFF7CF),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Color(0xff439775),
      ),
    ),
  );
}

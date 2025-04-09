import 'package:flutter/material.dart';
import 'settings_service.dart';

class FontSizeProvider extends ChangeNotifier {
  final SettingsService _settingsService;
  double _fontSize = 20.0;

  FontSizeProvider(this._settingsService) {
    _loadFontSize();
    _settingsService.fontSizeStream.listen((size) {
      _fontSize = size;
      notifyListeners();
    });
  }

  double get fontSize => _fontSize;

  Future<void> _loadFontSize() async {
    _fontSize = await _settingsService.getFontSize();
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    await _settingsService.setFontSize(size);
    _fontSize = size;
    notifyListeners();
  }
}
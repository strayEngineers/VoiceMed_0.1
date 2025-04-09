import 'package:flutter/material.dart';
import '/l10n/l10n.dart';
import 'settings_service.dart';

class LocaleModel with ChangeNotifier {
  final SettingsService _settingsService;
  Locale _locale = L10n.all.first;

  LocaleModel(this._settingsService) {
    _loadLocale();
  }

  Locale get locale => _locale;

  void _loadLocale() async {
    _locale = await _settingsService.getLocale();
    notifyListeners();
  }

  void setLocale(Locale l) {
    if (!L10n.all.contains(l)) {
      return;
    }
    _locale = l;
    _settingsService.setLocale(l);
    notifyListeners();
  }
}
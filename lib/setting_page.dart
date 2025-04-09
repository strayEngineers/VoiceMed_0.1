// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, use_build_context_synchronously, library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations, unused_element, use_key_in_widget_constructors, annotate_overrides, avoid_print, unused_field

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'font_size.dart';
import 'theme.dart';
import 'locale.dart';

// Settings for application
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late double _fontSize;
  late bool _isDarkMode;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 讀取設定
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? 20.0;
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      String? languageCode = prefs.getString('languageCode');
      _locale =
          languageCode != null ? Locale(languageCode) : Locale("zh", "TW");
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: TextStyle(
            fontSize: fontSizeProvider.fontSize + 6,
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF439775),
        iconTheme: IconThemeData(
            color: Color(0xFFEFF7CF),
            size: 30 * fontSizeProvider.fontSize / 20),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(10.0, 0.0, 0, 0),
        child: ListView(children: [
          SizedBox(
            height: 20 * fontSizeProvider.fontSize / 20,
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, "/toggleTheme");
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.app_settings_alt_rounded,
                      size: 40 * fontSizeProvider.fontSize / 20,
                    ),
                    SizedBox(width: 10.0),
                    Text(
                      AppLocalizations.of(context)!.theme,
                      style: TextStyle(
                          fontSize: fontSizeProvider.fontSize + 2,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 30 * fontSizeProvider.fontSize / 20,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 5.0,
          ),
          Divider(
            height: 20 * fontSizeProvider.fontSize / 20,
            color: Colors.grey,
          ),
          SizedBox(
            height: 5.0,
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, "/changeLanguage");
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 40 * fontSizeProvider.fontSize / 20,
                    ),
                    SizedBox(width: 10.0),
                    Text(
                      AppLocalizations.of(context)!.language,
                      style: TextStyle(
                          fontSize: fontSizeProvider.fontSize + 2,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 30 * fontSizeProvider.fontSize / 20,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 5.0,
          ),
          Divider(
            height: 20 * fontSizeProvider.fontSize / 20,
            color: Colors.grey,
          ),
          SizedBox(
            height: 5.0,
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, "/changeFontSize");
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.font_download,
                      size: 40 * fontSizeProvider.fontSize / 20,
                    ),
                    SizedBox(width: 10.0),
                    Text(
                      AppLocalizations.of(context)!.fontsize,
                      style: TextStyle(
                          fontSize: fontSizeProvider.fontSize + 2,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 30 * fontSizeProvider.fontSize / 20,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// 切換螢幕顯示模式的設定頁面
class ToggleTheme extends StatefulWidget {
  @override
  _ToggleThemeState createState() => _ToggleThemeState();
}

class _ToggleThemeState extends State<ToggleTheme> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // 讀取主題設定
  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.theme,
          style: TextStyle(
            fontSize: fontSizeProvider.fontSize + 6,
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF439775),
        iconTheme: IconThemeData(
          color: Color(0xFFEFF7CF),
          size: 30.0,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 5.0, 0, 0),
        child: ListView(children: [
          SizedBox(
            height: 20.0,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 10,
            ),
            Text(
              AppLocalizations.of(context)!.darktheme,
              style: TextStyle(
                  fontSize: fontSizeProvider.fontSize,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(
              width: 100.0,
            ),
            Transform.scale(
              scale: 0.7,
              child: CupertinoSwitch(
                  activeColor: Color(0xFF439775),
                  value: themeProvider.isDarkMode,
                  onChanged: (bool value) {
                    final provider =
                        Provider.of<ThemeProvider>(context, listen: false);
                    provider.toggleTheme(value);
                    _saveTheme(value);
                  }),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _saveTheme(bool isDarkMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDarkMode);
  }
}

// 切換語言的設定頁面
class ChangeLanguage extends StatefulWidget {
  @override
  _ChangeLanguageState createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  // 讀取語言設定
  Future<void> _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('languageCode');
    setState(() {
      _locale =
          languageCode != null ? Locale(languageCode) : Locale("zh", "TW");
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeModel = Provider.of<LocaleModel>(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.language,
          style: TextStyle(
            fontSize: fontSizeProvider.fontSize + 6,
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF439775),
        iconTheme: IconThemeData(
          color: Color(0xFFEFF7CF),
          size: 30.0,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 5.0, 0, 0),
        child: ListView(
          children: [
            SizedBox(
              height: 20.0,
            ),
            Center(
              child: SizedBox(
                width: 250,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.changelan,
                      style: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontWeight: FontWeight.w500),
                    ),
                    IconButton(
                      onPressed: () {
                        if (localeModel.locale == Locale("zh", "TW")) {
                          localeModel.setLocale(Locale("en"));
                          _saveLanguage("en");
                        } else {
                          localeModel.setLocale(Locale("zh", "TW"));
                          _saveLanguage("zh");
                        }
                        print(localeModel.locale);
                      },
                      icon: Icon(
                        Icons.change_circle,
                        size: 30 * fontSizeProvider.fontSize / 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveLanguage(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('languageCode', languageCode);
  }
}

// 切換字體大小的設定頁面
class ChangeFontSize extends StatefulWidget {
  @override
  _ChangeFontSizeState createState() => _ChangeFontSizeState();
}

class _ChangeFontSizeState extends State<ChangeFontSize> {
  double? _fontSize;

  @override
  void initState() {
    super.initState();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? 20.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    if (_fontSize == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.fontsize,
          style: TextStyle(
            fontSize: fontSizeProvider.fontSize + 6,
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF439775),
        iconTheme: IconThemeData(
          color: Color(0xFFEFF7CF),
          size: 30 * fontSizeProvider.fontSize / 20,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 5.0, 0, 0),
        child: ListView(
          children: [
            SizedBox(height: 20),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.fontsize,
                        style: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 270,
                    child: SliderTheme(
                      data: Theme.of(context).sliderTheme.copyWith(
                            trackHeight: 6 * fontSizeProvider.fontSize / 20,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius:
                                  10 * fontSizeProvider.fontSize / 20,
                            ),
                          ),
                      child: Slider(
                        value: _fontSize!,
                        min: 18.0,
                        max: 24.0,
                        onChanged: (value) {
                          setState(() {
                            _fontSize = value;
                            fontSizeProvider.setFontSize(value);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFontSize(double fontSize) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('fontSize', fontSize);
  }
}

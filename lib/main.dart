// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, use_build_context_synchronously, library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations

import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import "package:permission_handler/permission_handler.dart";
import "package:provider/provider.dart";
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'font_size.dart';
import 'theme.dart';
import 'homepage.dart';
import 'medicine_search_page.dart';
import 'setting_page.dart';
import 'locale.dart';
import 'alarm_page.dart';
import '/l10n/l10n.dart';
import "faq.dart";
import 'settings_service.dart';
import "alarm_helper.dart";

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final AndroidFlutterLocalNotificationsPlugin
    androidFlutterLocalNotificationsPlugin =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()!;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _requestPermissions();
  await _initializeNotifications();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final settingsService = SettingsService();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider(settingsService)),
      ChangeNotifierProvider(create: (_) => LocaleModel(settingsService)),
      ChangeNotifierProvider(create: (_) => FontSizeProvider(settingsService)),
      Provider.value(value: settingsService),
    ],
    child: MyApp(),
  ));
}

Future<void> _requestPermissions() async {
  await Permission.camera.request();
  await Permission.storage.request();
  await androidFlutterLocalNotificationsPlugin.requestNotificationsPermission();
  await androidFlutterLocalNotificationsPlugin.requestExactAlarmsPermission();
}

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings initializationSettingsiOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsiOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
    debugPrint(notificationResponse.payload);
  });

  final AlarmHelper alarmHelper = AlarmHelper();
  const String esp32IP = '192.168.17.175';
  await alarmHelper.syncToESP32(esp32IP);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeModel = Provider.of<LocaleModel>(context);
    return MaterialApp(
      title: "藥袋會說話",
      themeMode: themeProvider.themeMode,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      supportedLocales: L10n.all,
      locale: localeModel.locale,
      routes: {
        "/": (context) => MyHomePage(),
        "/medicineSearch": (context) => MedicineSearchPage(),
        "/setting": (context) => SettingsPage(),
        "/toggleTheme": (context) => ToggleTheme(),
        "/changeLanguage": (context) => ChangeLanguage(),
        "/changeFontSize": (context) => ChangeFontSize(),
        "/alarm": (context) => AlarmPage(),
        "/faq": (context) => FAQPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

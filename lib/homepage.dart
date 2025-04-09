// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, use_build_context_synchronously, library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations, unused_element, use_key_in_widget_constructors, annotate_overrides, avoid_print, unused_local_variable

import "dart:convert";
import "dart:io";
import "scan_medicine_result_page.dart";
import 'package:permission_handler/permission_handler.dart';
import "package:flutter/services.dart";
import "package:image_picker/image_picker.dart";
import "package:http/http.dart" as http;
import "alarm_helper.dart";
import "alarm_info.dart";
import "schedule_alarm.dart";
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import "package:path_provider/path_provider.dart";
import "package:flutter/material.dart";
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import "package:provider/provider.dart";
import "font_size.dart";
import "util.dart";

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AlarmHelper _alarmHelper = AlarmHelper();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late ScheduleAlarm scheduleAlarmHelper;

  String? audioFilePathZh;
  String? audioFilePathEn;

  @override
  void initState() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    scheduleAlarmHelper = ScheduleAlarm(flutterLocalNotificationsPlugin);
    _alarmHelper.initializeDatabase().then((value) {
      print('database initialized');
    }).catchError((error) {
      print('database initialization error: $error');
    });
    super.initState();
  }

  Future<void> _checkCameraPermission() async {
    final fontSizeProvider = context.read<FontSizeProvider>();
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      var newStatus = await Permission.camera.request();

      if (!newStatus.isGranted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.permissiontext1,
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize,
              ),
            ),
            content: Text(
              AppLocalizations.of(context)!.permissiontext2,
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  AppLocalizations.of(context)!.permissiontext3,
                  style: TextStyle(
                    fontSize: fontSizeProvider.fontSize - 2,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: Text(
                  AppLocalizations.of(context)!.permissiontext4,
                  style: TextStyle(
                    fontSize: fontSizeProvider.fontSize - 2,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _checkStoragePermission() async {
    final fontSizeProvider = context.read<FontSizeProvider>();
    var storageStatus = await Permission.storage.status;

    if (!storageStatus.isGranted) {
      var newStatus = await Permission.storage.request();

      if (!newStatus.isGranted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.permissiontext5,
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize,
              ),
            ),
            content: Text(
              AppLocalizations.of(context)!.permissiontext6,
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  AppLocalizations.of(context)!.permissiontext3,
                  style: TextStyle(
                    fontSize: fontSizeProvider.fontSize - 2,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: Text(
                  AppLocalizations.of(context)!.permissiontext4,
                  style: TextStyle(
                    fontSize: fontSizeProvider.fontSize - 2,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.leaveapp,
              style: TextStyle(fontSize: fontSizeProvider.fontSize),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Icon(Icons.cancel,
                    color: Colors.red,
                    size: 45 * fontSizeProvider.fontSize / 20),
              ),
              TextButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: Icon(Icons.check,
                    color: Colors.green,
                    size: 45 * fontSizeProvider.fontSize / 20),
              ),
            ],
          ),
        );
        return shouldLeave ?? false;
      },
      child: Scaffold(
        body: Center(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image(
                        image: AssetImage(isLightTheme
                            ? "assets/image/logo_light.png"
                            : "assets/image/logo_dark.png"),
                        width: 170 * fontSizeProvider.fontSize / 20,
                      )
                    ],
                  ),
                  SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          showScanOptionsDialog(context);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 100 * fontSizeProvider.fontSize / 20,
                              height: 100 * fontSizeProvider.fontSize / 20,
                              decoration: BoxDecoration(
                                  color: Color(0xff439775),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8))),
                              child: Icon(
                                Icons.document_scanner_rounded,
                                size: 80 * fontSizeProvider.fontSize / 20,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(AppLocalizations.of(context)!.function1,
                                style: TextStyle(
                                    fontSize: fontSizeProvider.fontSize)),
                          ],
                        ),
                      ),
                      SizedBox(width: 40),
                      InkWell(
                        onTap: () async {
                          _checkCameraPermission();
                          var cameraStatus = await Permission.camera.status;
                          if (cameraStatus.isGranted) {
                            Navigator.pushNamed(context, '/medicineSearch');
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 100 * fontSizeProvider.fontSize / 20,
                              height: 100 * fontSizeProvider.fontSize / 20,
                              decoration: BoxDecoration(
                                  color: Color(0xff439775),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8))),
                              child: Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 80 * fontSizeProvider.fontSize / 20,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(AppLocalizations.of(context)!.function2,
                                style: TextStyle(
                                    fontSize: fontSizeProvider.fontSize)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, "/alarm");
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 100 * fontSizeProvider.fontSize / 20,
                              height: 100 * fontSizeProvider.fontSize / 20,
                              decoration: BoxDecoration(
                                  color: Color(0xff439775),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8))),
                              child: Icon(
                                Icons.alarm_rounded,
                                size: 80 * fontSizeProvider.fontSize / 20,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(AppLocalizations.of(context)!.function3,
                                style: TextStyle(
                                    fontSize: fontSizeProvider.fontSize)),
                          ],
                        ),
                      ),
                      SizedBox(width: 40),
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, "/faq");
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 100 * fontSizeProvider.fontSize / 20,
                              height: 100 * fontSizeProvider.fontSize / 20,
                              decoration: BoxDecoration(
                                  color: Color(0xff439775),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8))),
                              child: Icon(
                                Icons.question_answer_rounded,
                                size: 80 * fontSizeProvider.fontSize / 20,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(AppLocalizations.of(context)!.function4,
                                style: TextStyle(
                                    fontSize: fontSizeProvider.fontSize)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 40,
                right: 30,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, "/setting");
                  },
                  child: Icon(
                    Icons.settings,
                    size: 30 * fontSizeProvider.fontSize / 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showScanOptionsDialog(BuildContext context) async {
    final fontSizeProvider = context.read<FontSizeProvider>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.select,
              style: TextStyle(fontSize: fontSizeProvider.fontSize + 4)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _takePhoto();
              },
              child: Icon(
                Icons.camera_alt,
                size: 60 * fontSizeProvider.fontSize / 20,
                color: Color(0xFF439775),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _getImageFromGallery();
              },
              child: Icon(
                Icons.photo_library,
                size: 60 * fontSizeProvider.fontSize / 20,
                color: Color(0xFF439775),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _getImageFromGallery() async {
    _checkStoragePermission();

    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      return false;
    }

    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      await _sendImageToAPI(File(pickedImage.path));
    } else {
      showSnackBar(context, AppLocalizations.of(context)!.getimage);
    }
    return true;
  }

  Future<bool> _takePhoto() async {
    _checkCameraPermission();

    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      return false;
    }

    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      await _sendImageToAPI(File(pickedImage.path));
    } else {
      showSnackBar(context, AppLocalizations.of(context)!.takephoto);
    }
    return true;
  }

  Future<void> _sendImageToAPI(File imageFile) async {
    final fontSizeProvider = context.read<FontSizeProvider>();
    const String esp32IP = '192.168.17.175';

    try {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40 * fontSizeProvider.fontSize / 20,
                  height: 40 * fontSizeProvider.fontSize / 20,
                  child: CircularProgressIndicator(),
                ),
                SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.upload1,
                  style: TextStyle(fontSize: fontSizeProvider.fontSize + 2),
                ),
              ],
            ),
          );
        },
      );

      var request = http.MultipartRequest(
          "POST", Uri.parse("http://192.168.17.253:8080/"));
      request.files
          .add(await http.MultipartFile.fromPath("image", imageFile.path));

      var response = await request.send().timeout(Duration(seconds: 10));
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var jsonData = json.decode(responseBody);
        String chineseText = jsonData["text"];
        String englishText = jsonData['translated_text'];

        bool hasCheckbox = jsonData["checkbox"] != null &&
            (jsonData["checkbox"] as List).isNotEmpty;

        await _downloadFile(jsonData['audio_files']['zh'], 'output_zh-TW.mp3');
        await _downloadFile(jsonData['audio_files']['en'], 'output_en.mp3');

        if (hasCheckbox) {
          for (var data in jsonData["checkbox"]) {
            var result = await _alarmHelper.maxId();
            var id = result + 1;
            var alarmInfo = AlarmInfo(
                id: id,
                title: data["title"],
                alarmDateTime: DateTime.parse(data["alarmDateTime"]),
                isRepeating: data["isRepeating"],
                isEnabled: data["isEnabled"],
                gradientColorIndex: data["gradientColorIndex"]);
            print('alarm inserted id: ${alarmInfo.id}');
            _alarmHelper.insertAlarm(alarmInfo);
            await _alarmHelper.syncToESP32(esp32IP);
            scheduleAlarmHelper.scheduleAlarm(
                alarmInfo.alarmDateTime!, alarmInfo,
                isRepeating: alarmInfo.isRepeating!);
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanMedicineResultPage(
                chineseText: chineseText,
                englishText: englishText,
                hasCheckbox: hasCheckbox),
          ),
        );
      } else {
        showSnackBar(context, AppLocalizations.of(context)!.upload2);
      }
    } catch (e) {
      Navigator.of(context).pop();
      showSnackBar(context, AppLocalizations.of(context)!.upload2);
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);
        print('檔案已下載並儲存於: $filePath');

        if (fileName.contains('zh')) {
          audioFilePathZh = filePath;
        } else if (fileName.contains('en')) {
          audioFilePathEn = filePath;
        }
      } else {
        print('下載檔案失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('下載過程中發生錯誤: $e');
    }
  }
}

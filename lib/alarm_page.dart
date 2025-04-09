// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, use_build_context_synchronously, library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations, unused_element, use_key_in_widget_constructors, annotate_overrides, avoid_print, no_leading_underscores_for_local_identifiers

import "alarm_helper.dart";
import "schedule_alarm.dart";
import "theme_data.dart";
import "alarm_info.dart";
import "package:flutter/material.dart";
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";
import "font_size.dart";

class AlarmPage extends StatefulWidget {
  @override
  _AlarmPageState createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  DateTime? _alarmTime;
  late String _alarmTimeString;
  bool _isRepeatSelected = false;
  final AlarmHelper _alarmHelper = AlarmHelper();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late ScheduleAlarm scheduleAlarmHelper;
  Future<List<AlarmInfo>>? _alarms;
  List<AlarmInfo>? _currentAlarms;
  final TextEditingController _titleController = TextEditingController();
  final String esp32IP = '192.168.17.175';
  // late AlarmInfo alarmInfo;

  @override
  void initState() {
    _alarmTime = DateTime.now();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    scheduleAlarmHelper = ScheduleAlarm(flutterLocalNotificationsPlugin);
    _alarmHelper.initializeDatabase().then((value) {
      print('database initialized');
      loadAlarms();
    }).catchError((error) {
      print('database initialization error: $error');
    });
    super.initState();
  }

  // get alarm data from database
  void loadAlarms() {
    _alarms = _alarmHelper.getAlarms();
    _alarms?.then((value) {
      print('alarms loaded: $value');
    }).catchError((error) {
      print('error loading alarms: $error');
    });
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    var appBar = AppBar(
      title: Text(
        AppLocalizations.of(context)!.alarmreminder,
        style: TextStyle(
            fontSize: fontSizeProvider.fontSize + 4,
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: Color(0xFF439775),
      iconTheme: IconThemeData(
          color: Color(0xFFEFF7CF), size: 30 * fontSizeProvider.fontSize / 20),
      leading: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, "/");
        },
        child: Icon(
          Icons.arrow_back,
        ),
      ),
    );

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamed(context, "/");
        return false;
      },
      child: Scaffold(
        appBar: appBar,
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: FutureBuilder<List<AlarmInfo>>(
                  future: _alarms,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: SizedBox(
                          width: 40 * fontSizeProvider.fontSize / 20,
                          height: 40 * fontSizeProvider.fontSize / 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF439775)),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    } else if (snapshot.data == null) {
                      return Center(
                        child: Text('No alarms found.'),
                      );
                    } else if (snapshot.hasData) {
                      _currentAlarms = snapshot.data;
                      return ListView(
                        children: snapshot.data!.map<Widget>((alarm) {
                          var alarmTime = DateFormat('hh:mm aa')
                              .format(alarm.alarmDateTime!);
                          var gradientColor = GradientTemplate
                              .gradientTemplate[alarm.gradientColorIndex!]
                              .colors;
                          return GestureDetector(
                            onTap: () {
                              _alarmTime = alarm.alarmDateTime;
                              _alarmTimeString = DateFormat('HH:mm')
                                  .format(alarm.alarmDateTime!);
                              _isRepeatSelected = alarm.isRepeating ?? false;
                              _titleController.text = alarm.title!;
                              showModalBottomSheet(
                                useRootNavigator: true,
                                context: context,
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setModalState) {
                                      return Container(
                                        padding: const EdgeInsets.all(32),
                                        child: Column(
                                          children: [
                                            TextButton(
                                              onPressed: () async {
                                                var selectedTime =
                                                    await showTimePicker(
                                                  context: context,
                                                  initialTime:
                                                      TimeOfDay.fromDateTime(
                                                          alarm.alarmDateTime!),
                                                  hourLabelText: "",
                                                  minuteLabelText: "",
                                                  builder:
                                                      (BuildContext context,
                                                          Widget? child) {
                                                    return Theme(
                                                      data: ThemeData.light()
                                                          .copyWith(
                                                        primaryColor:
                                                            Color(0xFF439775),
                                                        colorScheme:
                                                            ColorScheme.light(
                                                                primary: Color(
                                                                    0xFF439775)),
                                                        buttonTheme:
                                                            ButtonThemeData(
                                                          textTheme:
                                                              ButtonTextTheme
                                                                  .primary,
                                                        ),
                                                      ),
                                                      child: child!,
                                                    );
                                                  },
                                                );
                                                if (selectedTime != null) {
                                                  final now = DateTime.now();
                                                  var selectedDateTime =
                                                      DateTime(
                                                    now.year,
                                                    now.month,
                                                    now.day,
                                                    selectedTime.hour,
                                                    selectedTime.minute,
                                                  );
                                                  _alarmTime = selectedDateTime;
                                                  setModalState(() {
                                                    _alarmTimeString =
                                                        DateFormat('HH:mm')
                                                            .format(
                                                                _alarmTime!);
                                                  });
                                                }
                                              },
                                              child: Text(
                                                _alarmTimeString,
                                                style: TextStyle(
                                                    fontSize: fontSizeProvider
                                                            .fontSize +
                                                        4,
                                                    color: Color(0xFF439775)),
                                              ),
                                            ),
                                            ListTile(
                                              title: Text(
                                                AppLocalizations.of(context)!
                                                    .repeat,
                                                style: TextStyle(
                                                    fontSize: fontSizeProvider
                                                            .fontSize -
                                                        2),
                                              ),
                                              trailing: Switch(
                                                activeTrackColor:
                                                    Color(0xFF439775),
                                                onChanged: (value) {
                                                  setModalState(() {
                                                    _isRepeatSelected = value;
                                                  });
                                                },
                                                value: _isRepeatSelected,
                                              ),
                                            ),
                                            ListTile(
                                              title: Text(
                                                AppLocalizations.of(context)!
                                                    .title2,
                                                style: TextStyle(
                                                    fontSize: fontSizeProvider
                                                            .fontSize -
                                                        2),
                                              ),
                                              trailing: Icon(
                                                Icons.arrow_forward_ios,
                                                size: 23 *
                                                    fontSizeProvider.fontSize /
                                                    20,
                                              ),
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .enteralarmtitle,
                                                        style: TextStyle(
                                                            fontSize:
                                                                fontSizeProvider
                                                                    .fontSize),
                                                      ),
                                                      content: TextField(
                                                        cursorColor:
                                                            Color(0xFF439775),
                                                        controller:
                                                            _titleController,
                                                        style: TextStyle(
                                                          color:
                                                              Color(0xFF2A4747),
                                                          decoration:
                                                              TextDecoration
                                                                  .none,
                                                        ),
                                                        decoration:
                                                            InputDecoration(
                                                          hintText:
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .alarmtitle,
                                                          hintStyle: TextStyle(
                                                            fontSize:
                                                                fontSizeProvider
                                                                        .fontSize -
                                                                    2,
                                                            color: Color(
                                                                0xFF2A4747),
                                                          ),
                                                          enabledBorder:
                                                              UnderlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xFF2A4747)),
                                                          ),
                                                          focusedBorder:
                                                              UnderlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xFF2A4747)),
                                                          ),
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .cancel,
                                                            style: TextStyle(
                                                                color: Color(
                                                                    0xFF439775),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize:
                                                                    fontSizeProvider
                                                                            .fontSize -
                                                                        2),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            setModalState(
                                                                () {}); // Refresh the state
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .done,
                                                            style: TextStyle(
                                                                color: Color(
                                                                    0xFF439775),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize:
                                                                    fontSizeProvider
                                                                            .fontSize -
                                                                        2),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            FloatingActionButton.extended(
                                              onPressed: () {
                                                onUpdateAlarm(alarm.id,
                                                    _isRepeatSelected);
                                              },
                                              icon: Icon(Icons.alarm_rounded,
                                                  size: 25 *
                                                      fontSizeProvider
                                                          .fontSize /
                                                      20),
                                              label: Text(
                                                  AppLocalizations.of(context)!
                                                      .save,
                                                  style: TextStyle(
                                                      fontSize: fontSizeProvider
                                                              .fontSize -
                                                          2)),
                                              backgroundColor:
                                                  Color(0xFF439775),
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 32),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradientColor,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradientColor.last.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                    offset: Offset(4, 4),
                                  )
                                ],
                                borderRadius:
                                    BorderRadius.all(Radius.circular(24)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.label,
                                            color: Color(0xFF2A4747),
                                            size: 22 *
                                                fontSizeProvider.fontSize /
                                                20,
                                          ),
                                          SizedBox(
                                            width: 8,
                                          ),
                                          Text(
                                            alarm.title!,
                                            style: TextStyle(
                                                color: Color(0xFF2A4747),
                                                fontSize:
                                                    fontSizeProvider.fontSize),
                                          ),
                                        ],
                                      ),
                                      Switch(
                                        onChanged: (bool value) async {
                                          setState(() {
                                            toggleAlarm(alarm, value);
                                          });
                                        },
                                        value: alarm.isEnabled!,
                                        activeColor: Colors.white,
                                        activeTrackColor: Color(0xFF439775),
                                      )
                                    ],
                                  ),
                                  Text(
                                    alarm.isRepeating == true
                                        ? AppLocalizations.of(context)!.everyday
                                        : '',
                                    style: TextStyle(
                                        color: Color(0xFF2A4747),
                                        fontSize:
                                            fontSizeProvider.fontSize - 8),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        alarmTime,
                                        style: TextStyle(
                                          color: Color(0xFF2A4747),
                                          fontSize: fontSizeProvider.fontSize,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        iconSize:
                                            22 * fontSizeProvider.fontSize / 20,
                                        color: Color(0xFF2A4747),
                                        onPressed: () {
                                          deleteAlarm(alarm.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).followedBy([
                          // if (_currentAlarms!.length < 5)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Color(0xFF439775),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(24)),
                            ),
                            child: MaterialButton(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              onPressed: () {
                                _alarmTime = null;
                                _alarmTimeString =
                                    DateFormat('HH:mm').format(DateTime.now());
                                showModalBottomSheet(
                                    useRootNavigator: true,
                                    context: context,
                                    clipBehavior: Clip.antiAlias,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                    ),
                                    builder: (context) {
                                      return StatefulBuilder(
                                          builder: (context, setModalState) {
                                        return Container(
                                          padding: const EdgeInsets.all(32),
                                          child: Column(
                                            children: [
                                              TextButton(
                                                onPressed: () async {
                                                  var selectedTime =
                                                      await showTimePicker(
                                                    context: context,
                                                    initialTime:
                                                        TimeOfDay.now(),
                                                    hourLabelText: "",
                                                    minuteLabelText: "",
                                                    builder:
                                                        (BuildContext context,
                                                            Widget? child) {
                                                      return Theme(
                                                        data: ThemeData.light()
                                                            .copyWith(
                                                          primaryColor:
                                                              Color(0xFF439775),
                                                          colorScheme:
                                                              ColorScheme.light(
                                                                  primary: Color(
                                                                      0xFF439775)),
                                                          buttonTheme:
                                                              ButtonThemeData(
                                                            textTheme:
                                                                ButtonTextTheme
                                                                    .primary,
                                                          ),
                                                        ),
                                                        child: child!,
                                                      );
                                                    },
                                                  );
                                                  if (selectedTime != null) {
                                                    final now = DateTime.now();
                                                    var selectedDateTime =
                                                        DateTime(
                                                      now.year,
                                                      now.month,
                                                      now.day,
                                                      selectedTime.hour,
                                                      selectedTime.minute,
                                                    );
                                                    _alarmTime =
                                                        selectedDateTime;
                                                    setModalState(() {
                                                      _alarmTimeString =
                                                          DateFormat('HH:mm')
                                                              .format(
                                                                  _alarmTime!);
                                                    });
                                                  }
                                                },
                                                child: Text(
                                                  _alarmTimeString,
                                                  style: TextStyle(
                                                      fontSize: fontSizeProvider
                                                              .fontSize +
                                                          4,
                                                      color: Color(0xFF439775)),
                                                ),
                                              ),
                                              ListTile(
                                                title: Text(
                                                  AppLocalizations.of(context)!
                                                      .repeat,
                                                  style: TextStyle(
                                                      fontSize: fontSizeProvider
                                                              .fontSize -
                                                          2),
                                                ),
                                                trailing: Switch(
                                                  onChanged: (value) {
                                                    setModalState(() {
                                                      _isRepeatSelected = value;
                                                    });
                                                  },
                                                  value: _isRepeatSelected,
                                                  activeColor: Colors.white,
                                                  activeTrackColor:
                                                      Color(0xFF439775),
                                                ),
                                              ),
                                              ListTile(
                                                title: Text(
                                                  AppLocalizations.of(context)!
                                                      .title2,
                                                  style: TextStyle(
                                                      fontSize: fontSizeProvider
                                                              .fontSize -
                                                          2),
                                                ),
                                                trailing: Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 23 *
                                                      fontSizeProvider
                                                          .fontSize /
                                                      20,
                                                ),
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .enteralarmtitle,
                                                          style: TextStyle(
                                                              fontSize:
                                                                  fontSizeProvider
                                                                      .fontSize),
                                                        ),
                                                        content: TextField(
                                                          cursorColor:
                                                              Color(0xFF439775),
                                                          controller:
                                                              _titleController,
                                                          style: TextStyle(
                                                            color: Color(
                                                                0xFF2A4747),
                                                            decoration:
                                                                TextDecoration
                                                                    .none,
                                                          ),
                                                          decoration:
                                                              InputDecoration(
                                                            hintText:
                                                                AppLocalizations.of(
                                                                        context)!
                                                                    .alarmtitle,
                                                            hintStyle:
                                                                TextStyle(
                                                              fontSize:
                                                                  fontSizeProvider
                                                                          .fontSize -
                                                                      2,
                                                              color: Color(
                                                                  0xFF2A4747),
                                                            ),
                                                            enabledBorder:
                                                                UnderlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Color(
                                                                      0xFF2A4747)),
                                                            ),
                                                            focusedBorder:
                                                                UnderlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Color(
                                                                      0xFF2A4747)),
                                                            ),
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .cancel,
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0xFF439775),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize:
                                                                      fontSizeProvider
                                                                              .fontSize -
                                                                          2),
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              setModalState(
                                                                  () {});
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: Text(
                                                              AppLocalizations.of(
                                                                      context)!
                                                                  .done,
                                                              style: TextStyle(
                                                                  color: Color(
                                                                      0xFF439775),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize:
                                                                      fontSizeProvider
                                                                              .fontSize -
                                                                          2),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                              FloatingActionButton.extended(
                                                onPressed: () {
                                                  onSaveAlarm(
                                                      _isRepeatSelected);
                                                },
                                                icon: Icon(Icons.alarm_rounded,
                                                    size: 25 *
                                                        fontSizeProvider
                                                            .fontSize /
                                                        20),
                                                label: Text(
                                                  AppLocalizations.of(context)!
                                                      .save,
                                                  style: TextStyle(
                                                      fontSize: fontSizeProvider
                                                              .fontSize -
                                                          2),
                                                ),
                                                backgroundColor:
                                                    Color(0xFF439775),
                                              )
                                            ],
                                          ),
                                        );
                                      });
                                    });
                              },
                              child: Column(
                                children: <Widget>[
                                  Icon(Icons.add_alarm,
                                      size: 32 * fontSizeProvider.fontSize / 20,
                                      color: Colors.white),
                                  SizedBox(height: 8),
                                  Text(AppLocalizations.of(context)!.addalarm,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              fontSizeProvider.fontSize + 2))
                                ],
                              ),
                            ),
                          )
                        ]).toList(),
                      );
                    }
                    return Center(child: Text('No data'));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onSaveAlarm(bool _isRepeating) {
    DateTime? scheduleAlarmDateTime;
    _alarmTime ??= DateTime.now().add(Duration(days: 1));
    if (_alarmTime!.isAfter(DateTime.now())) {
      scheduleAlarmDateTime = _alarmTime;
    } else {
      scheduleAlarmDateTime = _alarmTime!.add(Duration(days: 1));
    }

    var alarmInfo = AlarmInfo(
        alarmDateTime: scheduleAlarmDateTime,
        gradientColorIndex: _currentAlarms!.length % 5,
        title: (_titleController.text != "" && _titleController.text.isNotEmpty)
            ? _titleController.text
            : AppLocalizations.of(context)!.alarm,
        isRepeating: _isRepeating,
        isEnabled: true);

    _alarmHelper.insertAlarm(alarmInfo).then((value) {
      alarmInfo.id = value;
      if (scheduleAlarmDateTime != null) {
        scheduleAlarmHelper.scheduleAlarm(scheduleAlarmDateTime, alarmInfo,
            isRepeating: _isRepeating);
      }
      Navigator.pop(context);
      loadAlarms();
    }).catchError((error) {
      print('error inserting alarm: $error');
    });

    _alarmHelper.syncToESP32(esp32IP);

/*     _alarmHelper.syncToESP32(esp32IP).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步到ESP32成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步到ESP32失敗')),
        );
      }
    }); */
  }

  void deleteAlarm(int? id) async {
    await flutterLocalNotificationsPlugin.cancel(id!);
    _alarmHelper.delete(id).then((value) {
      print('alarm deleted');
      loadAlarms();
    }).catchError((error) {
      print('error deleting alarm: $error');
    });

    await _alarmHelper.syncToESP32(esp32IP);
  }

  // Alarm's switch
  void toggleAlarm(AlarmInfo alarm, bool isEnabled) async {
    setState(() {
      alarm.isEnabled = isEnabled;
    });

    _alarmHelper.updateAlarm(alarm);

    // switch on : alarm on (scheduleAlarm)
    if (isEnabled) {
      scheduleAlarmHelper.scheduleAlarm(alarm.alarmDateTime!, alarm,
          isRepeating: alarm.isRepeating!);
    }
    // switch off : alarm off (cancel)
    else {
      await flutterLocalNotificationsPlugin.cancel(alarm.id!);
      print('cancel alarm id: ${alarm.id}');
    }

    await _alarmHelper.syncToESP32(esp32IP);
  }

  void onUpdateAlarm(int? alarmId, bool isRepeating) async {
    DateTime scheduleAlarmDateTime;
    if (_alarmTime!.isAfter(DateTime.now())) {
      scheduleAlarmDateTime = _alarmTime!;
    } else {
      scheduleAlarmDateTime = _alarmTime!.add(Duration(days: 1));
    }

    // new data of the specific alarm (with alarmId)
    var updatedAlarmInfo = AlarmInfo(
      id: alarmId,
      title: _titleController.text,
      alarmDateTime: scheduleAlarmDateTime,
      gradientColorIndex: 0,
      isRepeating: isRepeating,
      isEnabled: true,
    );

    await flutterLocalNotificationsPlugin.cancel(alarmId!);
    await _alarmHelper.updateAlarm(updatedAlarmInfo);
    scheduleAlarmHelper.scheduleAlarm(scheduleAlarmDateTime, updatedAlarmInfo,
        isRepeating: isRepeating);
    Navigator.pop(context);
    loadAlarms();

    await _alarmHelper.syncToESP32(esp32IP);
  }
}

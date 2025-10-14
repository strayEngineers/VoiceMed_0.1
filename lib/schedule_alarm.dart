// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, use_build_context_synchronously, library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations, unused_element, use_key_in_widget_constructors, annotate_overrides, avoid_print

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'alarm_info.dart';

class ScheduleAlarm {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // 建構子
  ScheduleAlarm(this.flutterLocalNotificationsPlugin);

  // scheduleAlarm 函數
  Future<void> scheduleAlarm(DateTime scheduledNotificationDateTime, AlarmInfo alarmInfo, {required bool isRepeating}) async {
    print('Scheduling alarm at: $scheduledNotificationDateTime');
    print('Alarm id: ${alarmInfo.id}');
    print('Is repeating: $isRepeating');

    try {
      // 初始化時區
      tz.initializeTimeZones();
      var local = tz.getLocation('Asia/Taipei');

      // Android 通知的設定
      const AndroidNotificationDetails androidPlateformChannelSpecifics =
          AndroidNotificationDetails(
        'alarm_notif',
        'alarm_notif',
        channelDescription: 'Channel for Alarm notification',
        icon: '@mipmap/ic_launcher',
        importance: Importance.max,  // 確保通知的優先級最高
        priority: Priority.high,
      );

      // iOS 通知的設定
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: "thread_id",
      );

      // 通知的詳細設定
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlateformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics);

      print('Scheduling alarm at $scheduledNotificationDateTime with id ${alarmInfo.id}');

      // 判斷是否為重複鬧鐘
      if (isRepeating) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          alarmInfo.id!,
          "服藥提醒 Time to take medicine！",
          alarmInfo.title,
          tz.TZDateTime.from(scheduledNotificationDateTime, local),
          platformChannelSpecifics,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time, // 每天重複
        );
        print('Scheduled repeating alarm');
      } else {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          alarmInfo.id!,
          "服藥提醒 Time to take medicine！",
          alarmInfo.title,
          tz.TZDateTime.from(scheduledNotificationDateTime, local),
          platformChannelSpecifics,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        print('Scheduled one-time alarm');
      }
    } catch (e) {
      print('Error scheduling alarm: $e');
    }
  }
}

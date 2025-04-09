// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, use_build_context_synchronously, library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations, unused_element, use_key_in_widget_constructors, annotate_overrides, avoid_print, prefer_const_declarations, prefer_conditional_assignment, unnecessary_this, avoid_function_literals_in_foreach_calls, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'alarm_info.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

final String tableAlarm = 'alarm2';
final String columnId = 'id';
final String columnTitle = 'title';
final String columnDateTime = 'alarmDateTime';
final String columnRepeating = 'isRepeating';
final String columnEnabled = 'isEnabled';
final String columnColorIndex = 'gradientColorIndex';

class AlarmHelper {
  static Database? _database;
  static AlarmHelper? _alarmHelper;

  AlarmHelper._createInstance();
  factory AlarmHelper() {
    if (_alarmHelper == null) {
      _alarmHelper = AlarmHelper._createInstance();
    }
    return _alarmHelper!;
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database!;
  }

  Future<Database> initializeDatabase() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    var path = "${appDocDir.path}/alarm2.db";
    print('Database path: $path');

    var database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableAlarm (
            $columnId integer primary key autoincrement,
            $columnTitle text not null,
            $columnDateTime text not null,
            $columnRepeating integer,
            $columnEnabled integer DEFAULT 1,
            $columnColorIndex integer
          );
        ''');
      },
    );
    return database;
  }

  Future<int> insertAlarm(AlarmInfo alarmInfo) async {
    var db = await this.database;
    var result = await db.insert(tableAlarm, alarmInfo.toMap());
    print('result: $result');
    return result;
  }

  Future<List<AlarmInfo>> getAlarms() async {
    List<AlarmInfo> _alarms = [];

    var db = await this.database;
    var result = await db.query(tableAlarm);
    result.forEach((element) {
      var alarmInfo = AlarmInfo.fromMap(element);
      _alarms.add(alarmInfo);
    });
    return _alarms;
  }

  Future<AlarmInfo> getAlarm(int? id) async {
    var db = await this.database;
    var result =
        await db.query(tableAlarm, where: '$columnId = ?', whereArgs: [id]);
    late AlarmInfo alarmInfo;
    result.forEach((element) {
      alarmInfo = AlarmInfo.fromMap(element);
    });
    return alarmInfo;
  }

  Future<int> delete(int? id) async {
    var db = await this.database;
    return await db.delete(tableAlarm, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> updateAlarm(AlarmInfo alarmInfo) async {
    var db = await database;
    return await db.update(tableAlarm, alarmInfo.toMap(),
        where: '$columnId = ?', whereArgs: [alarmInfo.id]);
  }

  Future<int> maxId() async {
    var db = await database;
    var result = await db.rawQuery('SELECT MAX(id) as maxId FROM $tableAlarm;');
    if (result.isEmpty || result[0]['maxId'] == null) {
      result = [
        {'maxId': 0}
      ];
    }
    return result[0]["maxId"] as int;
  }

  Future<bool> syncToESP32(String espIP) async {
    try {
      // 獲取所有鬧鐘
      final alarms = await getAlarms();

      // 將鬧鐘數據轉換為JSON格式，增加日期部分
      final alarmsJson = {
        'alarms': alarms
            .map((alarm) => {
                  'id': alarm.id,
                  'time': DateFormat('HH:mm').format(alarm.alarmDateTime!),
                  'date': DateFormat('yyyy-MM-dd')
                      .format(alarm.alarmDateTime!), // 新增的日期格式
                  'isEnabled': alarm.isEnabled,
                  'isRepeating': alarm.isRepeating,
                })
            .toList(),
      };

      // 發送到ESP32
      final response = await http.post(
        Uri.parse('http://$espIP/api/alarms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(alarmsJson),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error syncing to ESP32: $e');
      return false;
    }
  }
}

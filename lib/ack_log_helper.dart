// ignore_for_file: prefer_const_constructors, unnecessary_this, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'ack_log.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; //test

const String tableAck = 'ack_log';
const String columnId = 'ackLogId';
const String columnAlarmId = 'alarmId';
const String columnAlarmDateTime = 'alarmDateTime';
const String columnResponseDateTime = 'responseDateTime';
const String columnIsReceived = 'isReceived';

class AckLogHelper {
  static Future<Database>? _database; // test: 原本是static Database? _database;
  static AckLogHelper? _instance;
  late http.Client _httpClient;// test: 新增一個 http.Client 屬性

  //AckLogHelper._createInstance();
  //factory AckLogHelper() {
  //  _instance ??= AckLogHelper._createInstance();
  //  return _instance!;
  //}

  //Future<Database> get database async {
  // _database ??= await _initializeDatabase();
  //  return _database!;
  //}
  
  Future<Database> get database async {
  // 將 await 移到這裡，確保回傳的是 Database 物件
    _database ??= _initializeDatabase();
    return await _database!;
  }

  // test: 這個 setter 僅用於單元測試，允許我們注入一個虛擬資料庫實例。
  AckLogHelper._createInstance({http.Client? client}) {
    // 如果沒有傳入，則使用預設的 http.Client
    _httpClient = client ?? http.Client();
  }
  
  // 修改 factory 建構函式以接收 http.Client 
  factory AckLogHelper({http.Client? client}) {
    _instance ??= AckLogHelper._createInstance(client: client);
    return _instance!;
  }

  @visibleForTesting
  set database(Future<Database>? newDatabase) {
    _database = newDatabase;
  }
  // test

  Future<Database> _initializeDatabase() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = '${appDocDir.path}/ack_log.db';
    print('Ack DB path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableAck (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnAlarmId INTEGER NOT NULL,
            $columnAlarmDateTime TEXT NOT NULL,
            $columnResponseDateTime TEXT,
            $columnIsReceived INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // ---------------- DB 操作區 ----------------

  Future<int> insertAckLog(AckLog log) async {
    final db = await database;

    // 避免重複存同一筆
    final existing = await db.query(
      tableAck,
      where: '$columnAlarmId = ? AND $columnAlarmDateTime = ?',
      whereArgs: [
        log.alarmId,
        log.alarmDateTime.toIso8601String(),
      ],
    );

    if (existing.isNotEmpty) {
      print('Ack log already exists for alarmId=${log.alarmId}');
      return existing.first[columnId] as int;
    }

    final result = await db.insert(tableAck, log.toMap());
    print('Inserted ack log: $result');
    return result;
  }

  Future<int> updateAckLogByAlarmId(int alarmId, DateTime newAlarmDateTime) async {
    Database db = await this.database;
    var result = await db.update(
      tableAck,
      {'alarmDateTime': newAlarmDateTime.toIso8601String()},
      where: 'alarmId = ?',
      whereArgs: [alarmId],
    );
    return result;
  }

  Future<List<AckLog>> getAckLogs() async {
    final db = await database;
    final result = await db.query(tableAck, orderBy: '$columnAlarmDateTime DESC');
    return result.map((e) => AckLog.fromMap(e)).toList();
  }

  Future<int> deleteAllLogs() async {
    final db = await database;
    return await db.delete(tableAck);
  }

  // ---------------- API 操作區 ----------------

  // 這個更新方法會找到現有的紀錄並更新它
  Future<int> updateAckLogResponse(AckLog log) async {
    final db = await database;
    return await db.update(
      tableAck,
      {
        columnResponseDateTime: log.responseDateTime?.toIso8601String(),
        columnIsReceived: log.isReceived ? 1 : 0,
      },
      where: '$columnAlarmId = ? AND $columnAlarmDateTime = ?',
      whereArgs: [log.alarmId, log.alarmDateTime.toIso8601String()],
    );
  }

  // 這是優化後的 fetchAndSaveAckFromESP 方法
  Future<bool> fetchAndSaveAckFromESP(String espIP) async {
    try {
      //final response = await http.get(Uri.parse('http://$espIP/alarm/ack'));
      final response = await _httpClient.get(Uri.parse('http://$espIP/alarm/ack')); //test
      if (response.statusCode != 200) {
        print('ESP32 request failed: ${response.statusCode}');
        return false;
      }

      final data = jsonDecode(response.body);
      if (data is! List) {
        print('Unexpected data format from ESP32');
        return false;
      }

      for (var item in data) {
        if (!_validateAckItem(item)) continue;

        final log = AckLog(
          alarmId: item['alarmId'],
          alarmTitle: item['title'] as String,
          alarmDateTime: DateTime.fromMillisecondsSinceEpoch(item['scheduledTime'] * 1000),
          responseDateTime: DateTime.fromMillisecondsSinceEpoch(item['timestamp'] * 1000),
          isReceived: item['isReceived'] ?? false,
        );

        await updateAckLogResponse(log);
      }
      return true;
    } catch (e) {
      print("Failed to fetch ack: $e");
      return false;
    }
  }

  bool _validateAckItem(dynamic item) {
    if (item is! Map) return false;
    return item.containsKey('alarmId') &&
           item.containsKey('scheduledTime') &&
           item.containsKey('timestamp');
  }
}

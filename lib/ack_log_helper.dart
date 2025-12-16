// ignore_for_file: prefer_const_constructors, unnecessary_this, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'ack_log.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

const String tableAck = 'ack_log';
const String columnId = 'ackLogId';
const String columnAlarmId = 'alarmId';
const String columnAlarmDateTime = 'alarmDateTime';
const String columnResponseDateTime = 'responseDateTime';
const String columnIsReceived = 'isReceived';
const Duration immediateThreshold = Duration(minutes: 15); // 定義立即服藥的閾值 (15 分鐘)
const Duration missedThreshold = Duration(minutes: 60); // 定義超時 (Missed) 的閾值，假設為 60 分鐘 (超過 1 小時就算忘記/超時)


class AckLogHelper {
  static Future<Database>? _database; // test: 原本是static Database? _database;
  static AckLogHelper? _instance;

  // ---------------- 圖表/測試專用區 ----------------
  AckLogHelper._createInstance();
  factory AckLogHelper() {
    _instance ??= AckLogHelper._createInstance();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = _initializeDatabase();
    }
    return await _database!;
  }

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

  //Future<List<AckLog>> getAckLogs() async {
  //  final db = await database;
  //  final result = await db.query(tableAck, orderBy: '$columnAlarmDateTime DESC');
  //  return result.map((e) => AckLog.fromMap(e)).toList();
  //}
  // 修改 getAckLogs 方法
  Future<List<AckLog>> getAckLogs({bool includeMock = false}) async {
    final db = await database;
    final result = await db.query(tableAck, orderBy: '$columnAlarmDateTime DESC');

    List<AckLog> allLogs = result.map((e) => AckLog.fromMap(e)).toList();
    
    // 判斷是否要加入 Mock 資料
    if (includeMock) {
      allLogs.addAll(defaultMockAckLogs);
    }
    return allLogs;
  }

  Future<int> deleteAllLogs() async {
    final db = await database;
    return await db.delete(tableAck);
  }

  // ---------------- API 操作區 ----------------
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

  Future<bool> fetchAndSaveAckFromESP(String espIP) async {
    try {
      final response = await http.get(Uri.parse('http://$espIP/alarm/ack'));
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

  // ---------------- 服藥率計算區 ----------------
  Future<List<AdherenceData>> calculateAdherenceRate(
    List<AckLog> logs, 
    TimeGranularity granularity,
  ) async {
    if (logs.isEmpty) {
      return [];
    }

    Map<DateTime, List<AckLog>> groupedLogs = {}; // 步驟 A: 將所有紀錄按時間區間分組

    // 確定每個 log 屬於哪個時間區間的 Key
    DateTime getGroupKey(DateTime dateTime) {
      switch (granularity) {
        case TimeGranularity.Daily:
          return DateTime(dateTime.year, dateTime.month, dateTime.day); // 取日期本身 (當天 00:00:00)

        case TimeGranularity.Weekly:
          
          final day = DateTime(dateTime.year, dateTime.month, dateTime.day); // 尋找該周的星期一作為 Key
          return day.subtract(Duration(days: day.weekday - 1)); // 減去 (weekday - 1) 得到星期一

        case TimeGranularity.Monthly:
          return DateTime(dateTime.year, dateTime.month, 1); // 取該月的第一天作為 Key
      }
    }

    // 進行分組
    for (var log in logs) {
      final key = getGroupKey(log.alarmDateTime);
      groupedLogs.putIfAbsent(key, () => []).add(log);
    }

    // 計算每個區間的服藥率
    List<AdherenceData> results = [];

    groupedLogs.forEach((key, logList) {
      // 總提醒次數就是該時間區間內的 log 總數
      final totalScheduled = logList.length;
      
      // 已服藥次數：responseDateTime 不為 null 的 log
      final receivedCount = logList.where((log) => log.responseDateTime != null).length;

      // 計算服藥率
      final adherenceRate = totalScheduled > 0 ? (receivedCount / totalScheduled) : 0.0;

      results.add(AdherenceData(
        date: key,
        adherenceRate: adherenceRate,
        totalScheduled: totalScheduled,
      ));
    });
    
    // 按時間排序 (確保折線圖正確繪製)
    results.sort((a, b) => a.date.compareTo(b.date));

    return results;
  }

  // ---------------- 反應時間計算區 ----------------
  Future<List<ReactionTimeData>> calculateReactionTimeDistribution(
    List<AckLog> logs, 
    TimeGranularity granularity,
  ) async {
    if (logs.isEmpty) {
      return [];
    }

    // 步驟 A: 定義分組 Key 函數 (與服藥率邏輯相同)
    DateTime getGroupKey(DateTime dateTime) {
      // 這裡我們只處理 Weekly 和 Monthly，因為 Daily 長條圖資訊可能過多
      if (granularity == TimeGranularity.Weekly) {
        final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
        return day.subtract(Duration(days: day.weekday - 1));
      } else { // Monthly
        return DateTime(dateTime.year, dateTime.month, 1);
      }
    }

    // 步驟 B: 將所有紀錄按時間區間分組
    Map<DateTime, List<AckLog>> groupedLogs = {};
    for (var log in logs) {
      final key = getGroupKey(log.alarmDateTime);
      groupedLogs.putIfAbsent(key, () => []).add(log);
    }
    
    List<ReactionTimeData> results = []; // 步驟 C: 計算每個區間的計數

    groupedLogs.forEach((key, logList) {
      int immediate = 0;
      int delayed = 0;
      int missed = 0;

      for (var log in logList) {
        if (log.responseDateTime == null) {
          // 情況 1: 忘記服藥 (responseDateTime 為 null)
          missed++;
        } else {
          final reactionTime = log.responseDateTime!.difference(log.alarmDateTime); // 情況 2 & 3: 已服藥，計算反應時間
          if (reactionTime <= immediateThreshold) {
            // 情況 2: 立即服藥
            immediate++;
          } else if (reactionTime < missedThreshold) {
            // 情況 3: 延遲服藥 (在超時前回應)
            delayed++;
          } else {
            // 情況 4: 超時回應 (反應時間太長，視為忘記)
            missed++;
          }
        }
      }

      results.add(ReactionTimeData(
        date: key,
        immediateCount: immediate,
        delayedCount: delayed,
        missedCount: missed,
      ));
    });

    results.sort((a, b) => a.date.compareTo(b.date)); // 步驟 D: 按時間排序
    return results;
  }

  // ---------------- CSV 匯出區 ----------------
  String generateCsv(List<AckLog> logs) {
    List<List<dynamic>> rows = [];
    
    // 1. 新增標題行 (Header)
    rows.add([
      'Log ID', 
      'Alarm Title', 
      'Alarm Time', 
      'Response Time', 
      'Status (ACK/MISS)', 
      'Reaction Time (min)'
    ]);
    
    // 2. 轉換數據行 (Data Rows)
    for (var log in logs) {
      
      final reactionTime = log.responseDateTime?.difference(log.alarmDateTime); // 計算反應時間
      final reactionMinutes = reactionTime != null ? (reactionTime.inMilliseconds / (1000 * 60)).toStringAsFixed(1) : 'N/A'; // 將時間差轉換為分鐘，並保留一位小數

      rows.add([
        log.ackLogId,
        log.alarmTitle,
        log.alarmDateTime.toIso8601String(), // 國際標準格式
        log.responseDateTime?.toIso8601String() ?? 'N/A',
        log.responseDateTime != null ? 'ACK' : 'MISS',
        reactionMinutes,
      ]);
    }
    return const ListToCsvConverter().convert(rows); // 將 List<List<dynamic>> 轉換為 CSV 字串
  }
}

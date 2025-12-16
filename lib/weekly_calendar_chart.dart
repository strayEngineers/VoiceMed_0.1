// ignore_for_file: prefer_const_constructors, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 需要在 pubspec.yaml 中加入 intl 套件
import 'ack_log.dart'; // 確保路徑正確
// import 'dart:math' as math;

// ====================================================================
// 輔助 enum 和 Helper 類別：定義時間段
// ====================================================================

enum TimeSlot {
  MORNING,    // 05:00 - 11:59
  NOON,       // 12:00 - 13:59
  AFTERNOON,  // 14:00 - 18:59
  EVENING,    // 19:00 - 04:59 (跨夜)
}

// 獲取時間段的 Helper 函數
TimeSlot getTimeSlot(DateTime dateTime) {
  final hour = dateTime.hour;
  if (hour >= 5 && hour < 12) {
    return TimeSlot.MORNING;
  } else if (hour >= 12 && hour < 14) {
    return TimeSlot.NOON;
  } else if (hour >= 14 && hour < 19) {
    return TimeSlot.AFTERNOON;
  } else {
    // 19:00 (7PM) 到 04:59 (4:59 AM)
    return TimeSlot.EVENING;
  }
}

// ====================================================================
// 周曆圖 Widget
// ====================================================================

class WeeklyCalendarChart extends StatelessWidget {
  final List<AckLog> logs;
  final DateTime startDate;

  const WeeklyCalendarChart({super.key, required this.logs, required this.startDate});

  String getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return '一';
      case 2: return '二';
      case 3: return '三';
      case 4: return '四';
      case 5: return '五';
      case 6: return '六';
      case 7: return '日';
      default: return '';
    }
  }
  
  List<DateTime> getSevenDays(DateTime start) {
    final List<DateTime> days = [];
    final startDay = DateTime(start.year, start.month, start.day);
    for (int i = 0; i < 7; i++) {
      days.add(startDay.add(Duration(days: i)));
    }
    return days;
  }

  Map<TimeSlot, Map<DateTime, bool?>> _processLogs(List<AckLog> logs) {
    final sevenDays = getSevenDays(startDate);

    // 外層 Map Key: TimeSlot (早, 中, 午, 晚)
    // 內層 Map Key: DateTime (某一天 00:00:00)
    // 內層 Map Value: bool? (true=已回應, false=未回應/延遲, null=無提醒)
    final Map<TimeSlot, Map<DateTime, bool?>> data = {};
    
    for (var slot in TimeSlot.values) {
      data[slot] = {};
      for (var day in sevenDays) {
        data[slot]![day] = null;
      }
    }

    for (var log in logs) {
      final slot = getTimeSlot(log.alarmDateTime);
      final dayKey = DateTime(log.alarmDateTime.year, log.alarmDateTime.month, log.alarmDateTime.day);
      
      if (data.containsKey(slot) && data[slot]!.containsKey(dayKey)) {
        data[slot]![dayKey] = log.responseDateTime != null;
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final processedData = _processLogs(logs);
    final lastSevenDays = getSevenDays(startDate);
    
    // 樣式定義
    final slotNames = {
      TimeSlot.MORNING: '早',
      TimeSlot.NOON: '中',
      TimeSlot.AFTERNOON: '午',
      TimeSlot.EVENING: '晚',
    };
    
    // 決定方塊的顏色
    Color getCellColor(bool? isTaken) { //傳入bool?
      if (isTaken == null) {
        return Colors.grey.shade300;  //灰色：無提醒資料
      } else if (isTaken == true) {
        return Colors.green.shade400; //綠色：已服藥
      } else {
        return Colors.red.shade400;   //紅色：未服藥/延遲 (有提醒資料但無回應)
      }
    }

    // 決定方塊的內容
    Widget getCellContent(bool? isTaken) { // 傳入 bool?
      return Center(
        child: isTaken == true // 判斷是否為 true
          ? Icon(Icons.check, color: Colors.white, size: 16) 
          : isTaken == false // 判斷是否為 false
            ? Icon(Icons.close, color: Colors.white, size: 16)
            : const SizedBox.shrink(), // null (灰色) 時不顯示圖示
      );
    }

    // 橫向卷動的 Table
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Table(
          defaultColumnWidth: IntrinsicColumnWidth(), // <<< 響應式調整 1：改為 Intrinsic
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // 標頭列：星期與日期
            TableRow(
              children: [
                const SizedBox(width: 27.0, height: 40.0), // 第一個空白角
                
                // 星期 (一~日)
                ...lastSevenDays.map((day) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(getWeekdayName(day.weekday), 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(DateFormat('MM/dd').format(day), 
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),

            // 數據列：早中晚
            ...TimeSlot.values.map((slot) {
              return TableRow(
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 8.0),
                    height: 40,
                    child: Text(
                      slotNames[slot]!, 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),

                  // 數據欄：7 天的服藥紀錄方塊
                  ...lastSevenDays.map((day) {
                    final isTaken = processedData[slot]?[day]; // 檢查 processedData 是否包含該 Slot 和該 Day 的數據
                    
                    return Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Tooltip(
                        message: '${DateFormat('MM/dd').format(day)} ${slotNames[slot]!}\n'
                              '狀態: ${isTaken == true ? '已服藥' : (isTaken == false ? '未服藥' : '無提醒')}', // 更新 Tooltip
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: getCellColor(isTaken),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isTaken == null ? Colors.grey.shade400 : (isTaken == true ? Colors.green.shade700 : Colors.red.shade700), // 更新邊框顏色
                              width: 1,
                            ),
                          ),
                          child: getCellContent(isTaken),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
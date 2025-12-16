// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'ack_log.dart'; // 確保 AdherenceData 和 TimeGranularity 可用

class AdherenceLineChart extends StatelessWidget {
  final List<AdherenceData> data;
  final TimeGranularity granularity;

  const AdherenceLineChart({
    required this.data,
    required this.granularity,
  });

  // 格式化 X 軸標籤的 Helper
  String getTitleText(DateTime date) {
    switch (granularity) {
      case TimeGranularity.Daily:
        return DateFormat('MM/dd').format(date); // 例: 10/29
      case TimeGranularity.Weekly:
        return DateFormat('MM/dd').format(date); // 顯示週一日期
      case TimeGranularity.Monthly:
        return DateFormat('yyyy/MM').format(date); // 例: 2025/10
    }
  }

  // 將 AdherenceData 轉換為 LineChart 所需的 FlSpot
  List<FlSpot> _getSpots() {
    // 我們需要將日期轉換為一個數字索引 (X 軸)
    // 由於數據已經按時間排序，我們可以簡單地使用索引作為 X 值
    return data.asMap().entries.map((entry) {
      // entry.key 是索引 (0, 1, 2, ...), 作為 X 軸
      // adherenceRate 是 0.0 到 1.0，乘以 100 作為 Y 軸 (百分比)
      return FlSpot(entry.key.toDouble(), entry.value.adherenceRate * 100);
    }).toList();
  }

  // 構建 LineChartData
  LineChartData _getLineChartData(BuildContext context) {
    final spots = _getSpots();

    // X 軸標籤只顯示部分點，避免過度擁擠 (例如每隔 1 個點顯示)
    final int interval = granularity == TimeGranularity.Daily ? 1 : 1; 

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade300,
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.shade300,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        // ------------------ X 軸設定 ------------------
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30, // 預留空間給標籤
            interval: interval.toDouble(), // 控制標籤間隔
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                // 找到對應的日期
                final date = data[index].date;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8.0,
                  child: Transform.rotate(
                    angle: -45 * (3.1415926535 / 180), // 旋轉標籤 45 度以節省空間
                    child: Text(
                      getTitleText(date),
                      style: TextStyle(
                        //color: Theme.of(context).colorScheme.secondary,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }
              return SideTitleWidget(axisSide: meta.axisSide, child: Container());
            },
          ),
        ),
        // ------------------ Y 軸設定 ------------------
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 25, // 顯示 0, 25, 50, 75, 100
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: TextAlign.left,
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final index = touchedSpot.x.toInt();
              final dataPoint = data[index];
              
              // 顯示日期、服藥率和總次數
              return LineTooltipItem(
                '${getTitleText(dataPoint.date)}\n'
                '${touchedSpot.y.toStringAsFixed(1)}%\n'
                '(${dataPoint.totalScheduled} 次提醒)',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      minX: 0,
      maxX: (data.length - 1).toDouble(), // X 軸範圍從 0 到 數據點數-1
      minY: 0,
      maxY: 100, // Y 軸範圍 0% 到 100%
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true, // 平滑曲線
          color: Color(0xff439775), // 與主色調一致
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true), // 顯示數據點
          belowBarData: BarAreaData(
            show: true,
            color: Color(0xff439775).withOpacity(0.3), // 曲線下方填充顏色
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            '過去一段時間內無數據可供繪製服藥率圖表。',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    // 確保 X 軸至少有兩個點才能畫線
    if (data.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            '數據點不足 (至少需要 2 個點) 來繪製趨勢折線圖。',
            style: TextStyle(color: Colors.orange.shade800),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 16.0, 16.0),
      child: Container(
        height: 300, // 增加高度以容納 X 軸旋轉的標籤
        padding: const EdgeInsets.fromLTRB(10, 16, 0, 10), // 調整內邊距以容納標籤
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
        child: LineChart(_getLineChartData(context)),
      ),
    );
  }
}
// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'ack_log.dart';

class ReactionTimeChart extends StatelessWidget {
  final List<ReactionTimeData> data;
  final TimeGranularity granularity;

  const ReactionTimeChart({
    required this.data,
    required this.granularity,
  });

  String getTitleText(DateTime date) {
    switch (granularity) {
      case TimeGranularity.Weekly:
        final endOfWeek = date.add(Duration(days: 6));
        return '${DateFormat('MM/dd').format(date)} - ${DateFormat('MM/dd').format(endOfWeek)}';
      case TimeGranularity.Monthly:
        return DateFormat('yyyy/MM').format(date);
      // 雖然目前邏輯不支援 Daily，但寫上以防未來擴展
      case TimeGranularity.Daily:
        return DateFormat('MM/dd').format(date);
    }
  }

  // 定義各狀態的顏色
  static const Color immediateColor = Color(0xff439775);
  static const Color delayedColor = Color(0xfff6c547);
  static const Color missedColor = Color(0xfff44336);

  List<BarChartGroupData> _getBarGroups() {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      if (item.totalCount == 0) {
        return BarChartGroupData(x: index, barRods: []);
      }

      final double total = item.totalCount.toDouble();
      final double immediateRatio = item.immediateCount / total * 100;
      final double delayedRatio = item.delayedCount / total * 100;
      //final double missedRatio = item.missedCount / total * 100;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: 100,
            rodStackItems: [
              // 立即服藥 (綠)
              BarChartRodStackItem(
                0,
                immediateRatio,
                immediateColor,
              ),
              // 延遲服藥 (黃)
              BarChartRodStackItem(
                immediateRatio, // 起點是立即服藥的終點
                immediateRatio + delayedRatio, // 終點是立即+延遲的總和
                delayedColor,
              ),
              // 忘記服藥 (紅)
              BarChartRodStackItem(
                immediateRatio + delayedRatio, // 起點是立即+延遲的總和
                100,
                missedColor,
              ),
            ],
            borderRadius: BorderRadius.zero,
            width: 15, // 長條寬度
          ),
        ],
      );
    }).toList();
  }

  BarChartData _getBarChartData(BuildContext context) {
    final barGroups = _getBarGroups();

    return BarChartData(
      alignment: BarChartAlignment.center,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) => null, // 隱藏預設的 Tooltip
        ),
      ),
      // ------------------ 軸線設定 ------------------
      titlesData: FlTitlesData(
        show: true,
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        
        // X 軸標籤 (顯示時間區間，顯示在底部)
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                final date = data[index].date;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 0.0,
                  child: Transform.rotate( 
                    angle: -45 * (3.1415926535 / 180), // 讓 X 軸標籤旋轉
                    child: Text(
                      getTitleText(date),
                      style: TextStyle(
                        color: Colors.black,
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
        
        // Y 軸標籤 (顯示百分比，顯示在左側)
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 25, // 顯示 0%, 25%, 50%, 75%, 100%
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 4,
                child: Text(
                  '${value.toInt()}%',
                  style: TextStyle(fontSize: 10),
                  textAlign: TextAlign.left,
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false, // 隱藏垂直線
        drawHorizontalLine: true, // 顯示百分比的水平線
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade300,
          strokeWidth: 1,
          dashArray: [5, 5],
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      
      // 核心配置：預設垂直長條圖
      barGroups: barGroups,
      minY: 0,
      maxY: 100,
    );
  }

  // 圖例區域
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(immediateColor, '立即服藥 (<15分)'),
          _buildLegendItem(delayedColor, '延遲服藥'),
          _buildLegendItem(missedColor, '忘記/超時'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 10)),
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
            '無足夠數據可供繪製反應時間堆疊長條圖。',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 16.0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 圖表區域
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              child: BarChart(_getBarChartData(context)),
            ),
          ),
          
          // 圖例區域
          _buildLegend(), 
        ],
      ),
    );
  }
}
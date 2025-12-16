// ignore_for_file: prefer_const_constructors, avoid_print

import 'package:flutter/material.dart';
import 'ack_log.dart';
import 'ack_log_helper.dart';
import 'weekly_calendar_chart.dart';
import 'adherence_line_chart.dart';
import 'reaction_time_chart.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class AckLogPage extends StatefulWidget {
  const AckLogPage({super.key});

  @override
  State<AckLogPage> createState() => _AckLogPageState();
}

class _AckLogPageState extends State<AckLogPage> with SingleTickerProviderStateMixin {
  final AckLogHelper _ackLogHelper = AckLogHelper();
  Map<String, List<AckLog>> _logsByTitle = {};
  late TabController _tabController;
  TimeGranularity _selectedGranularity = TimeGranularity.Daily;
  TimeGranularity _selectedReactionGranularity = TimeGranularity.Weekly;
  late DateTime _selectedWeekStart;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedWeekStart = _findStartOfWeek(DateTime.now());
    _syncAndLoadData(); // 當頁面初始化，自動同步資料並載入圖表
  }

  DateTime _findStartOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _syncAndLoadData() async {
    const espIP = "192.168.0.108";
    await _ackLogHelper.fetchAndSaveAckFromESP(espIP); // 數據同步（調用 Service 層）
    //final allLogs = await _ackLogHelper.getAckLogs(); // 獲取所有原始數據
    final allLogs = await _ackLogHelper.getAckLogs(includeMock: true);
    final Map<String, List<AckLog>> groupedLogs = {}; // 初始化分組 Map

    // 遍歷並進行分組
    for (var log in allLogs) {
      final groupKey = log.alarmTitle.toLowerCase().trim();
      if (!groupedLogs.containsKey(groupKey)) {
        groupedLogs[groupKey] = [];
      }
      groupedLogs[groupKey]!.add(log);
    }
     
    // 更新狀態並觸發 UI 重新繪製
    setState(() {
      _logsByTitle = groupedLogs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoaded = _logsByTitle.isNotEmpty; 
    
    return Scaffold(
      appBar: AppBar(title: const Text('服藥追蹤')),
      body: !isLoaded
          ? const Center(child: CircularProgressIndicator()) 
          : ListView(
              children: [
                // 核心邏輯：遍歷 Map 的所有 Keys（即所有不同的提醒標題）
                for (var title in _logsByTitle.keys)
                  _buildMedicationGroup(
                    title,  
                    _logsByTitle[title]!,
                  ),
              ],
            ),
    );
  }
  
  // 輔助函式：用於生成特定藥物的所有圖表
  Widget _buildMedicationGroup(String title, List<AckLog> logs) {
    final lineChartData = _ackLogHelper.calculateAdherenceRate(logs, _selectedGranularity);
    final reactionChartData = _ackLogHelper.calculateReactionTimeDistribution(
          logs, 
          _selectedReactionGranularity,
          );
    final double chartHeight = MediaQuery.of(context).size.height * 0.4; // 定義圖表區的高度
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 標題與匯出按鈕
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$title 服藥追蹤',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.download, color: Theme.of(context).primaryColor),
                  tooltip: '匯出服藥紀錄 (CSV)',
                  onPressed: () {
                    _exportLogsToCsv(logs, title);
                  },
                ),
              ],
            ),
          ),
          
          // 2. Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: '服藥紀錄周曆'),
                Tab(text: '服藥規律趨勢'),
                Tab(text: '服藥反應時間'),
              ],
            ),
          ),
          
          // 3. Tab Bar View (包含所有圖表)
          Container(
            height: chartHeight,
            child: TabBarView(
              controller: _tabController,
              children: [
                // --- Tab 1: 周曆圖 (重點修改處) ---
                Column(
                  children: [
                    // 1. 周曆導航器
                    _buildWeekNavigator(),
                    // 2. 周曆圖表
                    Expanded(
                      child: Center(
                        child: WeeklyCalendarChart(
                          logs: logs,
                          startDate: _selectedWeekStart, 
                        ),
                      ),
                    ),
                  ],
                ),

                // --- Tab 2: 折線圖 (服藥率) ---
                Column(
                  children: [
                    // A. 時間粒度選擇器 (服藥率)
                    _buildGranularitySelector(
                      '服藥規律趨勢',
                      _selectedGranularity,
                      TimeGranularity.values,
                      (newValue) => setState(() => _selectedGranularity = newValue!),
                    ),
                    // B. 圖表
                    Expanded( 
                      child: FutureBuilder<List<AdherenceData>>(
                        future: lineChartData,
                        builder: _buildLineChart,
                      ),
                    ),
                  ],
                ),

                // --- Tab 3: 長條圖 (反應時間) --- 
                Column(
                  children: [
                    // A. 時間粒度選擇器 (反應時間)
                    _buildGranularitySelector(
                      '服藥反應時間',
                      _selectedReactionGranularity,
                      TimeGranularity.values.where((g) => g != TimeGranularity.Daily).toList(),
                      (newValue) => setState(() => _selectedReactionGranularity = newValue!),
                    ),
                    // B. 圖表
                    Expanded(
                      child: FutureBuilder<List<ReactionTimeData>>(
                        future: reactionChartData,
                        builder: _buildReactionChart,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 輔助函式：用於切換周曆的時間
  void _changeWeek(int days) {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(Duration(days: days));
    });
    _syncAndLoadData(); // 每次切換日期後，重新載入該週的數據
  }

  // 提取：周曆的日期選擇器 UI
  Widget _buildWeekNavigator() {
    final weekEnd = _selectedWeekStart.add(Duration(days: 6));
    final displayRange = '${DateFormat('MM/dd').format(_selectedWeekStart)} - ${DateFormat('MM/dd').format(weekEnd)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => _changeWeek(-7), // 往前切換 7 天
          ),
          Text(
            '周曆範圍: $displayRange',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () => _changeWeek(7), // 往後切換 7 天
          ),
        ],
      ),
    );
  }
  
  // 提取：圖表時間粒度選擇器
  Widget _buildGranularitySelector(
      String title,
      TimeGranularity selectedValue,
      List<TimeGranularity> availableValues,
      ValueChanged<TimeGranularity?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          DropdownButton<TimeGranularity>(
            value: selectedValue,
            items: availableValues.map((TimeGranularity value) {
              return DropdownMenuItem<TimeGranularity>(
                value: value,
                child: Text(value.name),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // 提取：服藥率折線圖的 FutureBuilder Builder
  Widget _buildLineChart(BuildContext context, AsyncSnapshot<List<AdherenceData>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      print('Adherence Line Chart Error: ${snapshot.error}');
      return Center(child: Text('載入服藥率數據錯誤'));
    }
    return AdherenceLineChart(
      data: snapshot.data ?? [],
      granularity: _selectedGranularity,
    );
  }

  // 提取：反應時間堆疊長條圖的 FutureBuilder Builder
  Widget _buildReactionChart(BuildContext context, AsyncSnapshot<List<ReactionTimeData>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      print('Reaction Time Chart Error: ${snapshot.error}');
      return Center(child: Text('載入反應時間數據錯誤'));
    }
    return ReactionTimeChart(
      data: snapshot.data ?? [],
      granularity: _selectedReactionGranularity,
    );
  }

  Future<void> _exportLogsToCsv(List<AckLog> logs, String title) async {
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('無紀錄可供匯出。')));
      return;
    }
    
    // 1. 請求儲存權限 (對於 Android 10 及以下可能需要，高版本通常不需要 Storage 權限，但為保險起見保留)
    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('需要儲存權限才能匯出檔案。')));
        return;
      }
    }
    
    final directory = await getTemporaryDirectory();  // 2. 獲取 APP 的臨時文件目錄
    
    try {
      final csvContent = _ackLogHelper.generateCsv(logs); // 3. 生成 CSV 內容
      final safeTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_'); // 4. 建立檔案路徑(替換 title 中的特殊符號掉，確保檔案名稱有效)
      final fileName = '${safeTitle}_logs_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csvContent); // 5. 寫入檔案
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV檔案已生成。'))); // 6. 提示使用者並提供分享選項
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'text/csv',
            name: fileName,
          )
        ],
      );
      
    } catch (e) {
      print('CSV Export Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('匯出失敗: ${e.toString()}')));
    }
  }
}
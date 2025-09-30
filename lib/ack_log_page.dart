// ignore_for_file: prefer_const_constructors, avoid_print

import 'package:flutter/material.dart';
import 'ack_log.dart';
import 'ack_log_helper.dart';

class AckLogPage extends StatefulWidget {
  const AckLogPage({Key? key}) : super(key: key);

  @override
  State<AckLogPage> createState() => _AckLogPageState();
}

class _AckLogPageState extends State<AckLogPage> {
  final AckLogHelper _ackLogHelper = AckLogHelper();
  Map<String, List<AckLog>> _logsByTitle = {}; // 這裡存放要顯示的服藥紀錄列表

  @override
  void initState() {
    super.initState();
    // 在頁面初始化時，自動同步資料並載入圖表
    _syncAndLoadData(); 
  }

  Future<void> _syncAndLoadData() async {
    final espIP = "192.168.0.108"; 
    await _ackLogHelper.fetchAndSaveAckFromESP(espIP); // 步驟 1: 數據同步（調用 Service 層）
    final allLogs = await _ackLogHelper.getAckLogs(); // 步驟 2: 獲取所有原始數據
    final Map<String, List<AckLog>> groupedLogs = {}; // 步驟 3: 初始化分組 Map

    // 步驟 4: 遍歷並進行分組（表現層邏輯）
    for (var log in allLogs) {
      final groupKey = log.alarmTitle.toLowerCase().trim(); // title 標準化
      // 如果這個 title 還不在 Map 中，就先創建一個新列表
      if (!groupedLogs.containsKey(groupKey)) {
        groupedLogs[groupKey] = [];
      }
      // 將當前紀錄加入對應 title 的列表
      groupedLogs[groupKey]!.add(log);
    }
      
    // 步驟 5: 更新狀態並觸發 UI 重新繪製
    setState(() {
      _logsByTitle = groupedLogs; 
    });
  }

  @override
  Widget build(BuildContext context) {
    // 檢查是否載入完成（_logsByTitle.isNotEmpty）
    final isLoaded = _logsByTitle.isNotEmpty; 
    
    return Scaffold(
      appBar: AppBar(title: const Text('服藥紀錄')),
      body: !isLoaded
          ? const Center(child: CircularProgressIndicator()) 
          : ListView(
              children: [
                // 核心邏輯：遍歷 Map 的所有 Keys（即所有不同的提醒標題）
                for (var title in _logsByTitle.keys)
                  _buildMedicationGroup(
                    // 原始標題 (用於顯示在 UI 上)
                    title, 
                    // 該標題下的所有紀錄 (傳給圖表 Widget)
                    _logsByTitle[title]!, 
                  ),
              ],
            ),
    );
  }

  // 輔助函式：用於生成特定藥物的所有圖表
  Widget _buildMedicationGroup(String title, List<AckLog> logs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顯示標題
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '$title 服藥追蹤', // 讓使用者知道這是哪種藥物/提醒的數據
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // 1. 服藥紀錄 周曆圖
          // WeeklyCalendarChart(logs: logs),
          // 2. 服藥率 折線圖
          // AdherenceLineChart(logs: logs),
          // 3. 反應時間 堆疊長條圖
          // ReactionTimeChart(logs: logs),
        ],
      ),
    );
  }
}

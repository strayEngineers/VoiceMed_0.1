class AckLog {
  int? ackLogId; // 主鍵，自增
  int alarmId; // 外鍵，對應 AlarmInfo.id
  String alarmTitle; //服藥提醒標題
  DateTime alarmDateTime; // 當次提醒的預定時間
  DateTime? responseDateTime; // 使用者實際點按時間
  bool isReceived; // 是否收到提醒

  AckLog({
    this.ackLogId,
    required this.alarmId,
    required this.alarmTitle, // 新增 alarmTitle
    required this.alarmDateTime,
    this.responseDateTime,
    this.isReceived = true,
  });

  // 反應時間計算
  Duration? get reactionTime => responseDateTime?.difference(alarmDateTime);

  // 從db取出值
  factory AckLog.fromMap(Map<String, dynamic> json) => AckLog(
        ackLogId: json["ackLogId"],
        alarmId: json["alarmId"],
        alarmTitle: json["title"],
        alarmDateTime: DateTime.parse(json["alarmDateTime"]),
        responseDateTime: json["responseDateTime"] != null
            ? DateTime.tryParse(json["responseDateTime"])
            : null,
        isReceived: json["isReceived"] == 1,
      );

  // 將值放入db
  Map<String, dynamic> toMap() => {
        "ackLogId": ackLogId,
        "alarmId": alarmId,
        "alarmTitle": alarmTitle,
        "alarmDateTime": alarmDateTime.toIso8601String(),
        "responseDateTime": responseDateTime?.toIso8601String(),
        "isReceived": isReceived ? 1 : 0,
      };
}

// 定義時間粒度，用於使用者介面選擇和數據分組
enum TimeGranularity {
  Daily,
  Weekly,
  Monthly,
}

// 儲存計算後的服藥率數據模型
class AdherenceData {
  final DateTime date; // 該時間點/區間的起始日期
  final double adherenceRate; // 服藥率 (0.0 到 1.0)
  final int totalScheduled; // 總提醒次數

  AdherenceData({
    required this.date,
    required this.adherenceRate,
    required this.totalScheduled,
  });
}

// 定義反應狀態
enum ReactionStatus {
  IMMEDIATE, // 立即服藥 (例如 <= 15 分鐘)
  DELAYED,   // 延遲服藥 (例如 > 15 分鐘 且 < 預定視窗)
  MISSED,    // 忘記服藥 (responseDateTime 為 null 或超時)
}

// 用於長條圖的單個數據點
class ReactionTimeData {
  final DateTime date; // 該時間區間的 Key (週一或月一)
  final int immediateCount;
  final int delayedCount;
  final int missedCount;

  ReactionTimeData({
    required this.date,
    required this.immediateCount,
    required this.delayedCount,
    required this.missedCount,
  });

  // 輔助屬性：計算總數
  int get totalCount => immediateCount + delayedCount + missedCount;
}

// ---------------- 測試資料 ----------------
final List<AckLog> defaultMockAckLogs = [
  // ====================================================================
    // 藥物 A: 多維生素 (AlarmId: 104) - 每日四次 (12/10 ~ 12/14)
  // ====================================================================
  // --- 12/10 (週三): 全數立即服藥 ---
  AckLog(ackLogId: 23, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 10, 8, 0, 0), responseDateTime: DateTime(2025, 12, 10, 8, 5, 0), isReceived: true,),
  AckLog(ackLogId: 24, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 10, 12, 0, 0), responseDateTime: DateTime(2025, 12, 10, 12, 7, 0), isReceived: true,),
  AckLog(ackLogId: 25, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 10, 16, 0, 0), responseDateTime: DateTime(2025, 12, 10, 16, 1, 0), isReceived: true,),
  AckLog(ackLogId: 26, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 10, 20, 0, 0), responseDateTime: DateTime(2025, 12, 10, 20, 10, 0), isReceived: true,),

  // --- 12/11 (週四): 兩次錯過 (null) + 兩次立即 ---
  AckLog(ackLogId: 27, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 11, 8, 0, 0), responseDateTime: null, isReceived: true,),
  AckLog(ackLogId: 28, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 11, 12, 0, 0), responseDateTime: null, isReceived: true,),
  AckLog(ackLogId: 29, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 11, 16, 0, 0), responseDateTime: DateTime(2025, 12, 11, 16, 15, 0), isReceived: true,), // 15 min
  AckLog(ackLogId: 30, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 11, 20, 0, 0), responseDateTime: DateTime(2025, 12, 11, 20, 8, 0), isReceived: true,), // 8 min

  // --- 12/12 (週五): 全數延遲服藥 ---
  AckLog(ackLogId: 31, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 12, 8, 0, 0), responseDateTime: DateTime(2025, 12, 12, 8, 45, 0), isReceived: true,),
  AckLog(ackLogId: 32, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 12, 12, 0, 0), responseDateTime: DateTime(2025, 12, 12, 12, 35, 0), isReceived: true,),
  AckLog(ackLogId: 33, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 12, 16, 0, 0), responseDateTime: DateTime(2025, 12, 12, 16, 20, 0), isReceived: true ,),
  AckLog(ackLogId: 34, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 12, 20, 0, 0), responseDateTime: DateTime(2025, 12, 12, 20, 50, 0), isReceived: true ,),

  // --- 12/13 (週六): 全數立即服藥 ---
  AckLog(ackLogId: 35, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 13, 8, 0, 0), responseDateTime: DateTime(2025, 12, 13, 8, 2, 0), isReceived: true,),
  AckLog(ackLogId: 36, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 13, 12, 0, 0), responseDateTime: DateTime(2025, 12, 13, 12, 5, 0), isReceived: true,),
  AckLog(ackLogId: 37, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 13, 16, 0, 0), responseDateTime: DateTime(2025, 12, 13, 16, 1, 0), isReceived: true,),
  AckLog(ackLogId: 38, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 13, 20, 0, 0), responseDateTime: DateTime(2025, 12, 13, 20, 10, 0), isReceived: true,),

  // --- 12/14 (週日): 全數錯過 (無回應) ---
  AckLog(ackLogId: 39, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 14, 8, 0, 0), responseDateTime: null, isReceived: true,),
  AckLog(ackLogId: 40, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 14, 12, 0, 0), responseDateTime: null, isReceived: true,),
  AckLog(ackLogId: 41, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 14, 16, 0, 0), responseDateTime: null, isReceived: true,),
  AckLog(ackLogId: 42, alarmId: 104, alarmTitle: '多維生素', alarmDateTime: DateTime(2025, 12, 14, 20, 0, 0), responseDateTime: null, isReceived: true,),
  
  // ====================================================================
    // [新增] 藥物 B: 降壓藥 - 2025年12月 (本週紀錄，12/01 ~ 12/07)
  // ====================================================================
  
  // ----------------------- 9 月 (測試 Monthly 分組) -----------------------
  
  // 9/01: 立即服藥 (10分鐘)
  AckLog(ackLogId: 1, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 9, 1, 8, 0, 0), responseDateTime: DateTime(2025, 9, 1, 8, 10, 0), isReceived: true,),
  // 9/08: 延遲服藥 (30分鐘)
  AckLog(ackLogId: 2, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 9, 8, 8, 0, 0), responseDateTime: DateTime(2025, 9, 8, 8, 30, 0), isReceived: true,),
  // 9/15: 忘記服藥 (無回應)
  AckLog(ackLogId: 3, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 9, 15, 8, 0, 0), responseDateTime: null, isReceived: false,),
  // 9/22: 超時服藥 (90分鐘, 視為 Missed)
  AckLog(ackLogId: 4, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 9, 22, 8, 0, 0), responseDateTime: DateTime(2025, 9, 22, 9, 30, 0), isReceived: true,),

  // ----------------------- 10 月 (測試 Weekly/Daily 分組) -----------------------
  
  // 10/01: 立即 (W1)
  AckLog(ackLogId: 5, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 10, 1, 8, 0, 0), responseDateTime: DateTime(2025, 10, 1, 8, 5, 0), isReceived: true,),
  // 10/08: 延遲 (W2)
  AckLog(ackLogId: 6, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 10, 8, 8, 0, 0), responseDateTime: DateTime(2025, 10, 8, 8, 20, 0), isReceived: true,),
  // 10/15: 忘記 (W3)
  AckLog(ackLogId: 7, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 10, 15, 8, 0, 0), responseDateTime: null, isReceived: false,),
  // 10/22: 立即 (W4)
  AckLog(ackLogId: 8, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 10, 22, 8, 0, 0), responseDateTime: DateTime(2025, 10, 22, 8, 1, 0), isReceived: true,),
  
  // ----------------------- 12 月 (本週紀錄，12/01 ~ 12/05) -----------------------
  
  // 12/01 (週一): 正常服藥 (5分鐘)
  AckLog(ackLogId: 10, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 12, 1, 8, 0, 0), responseDateTime: DateTime(2025, 12, 1, 8, 5, 0), isReceived: true,),
  // 12/02 (週二): 延遲服藥 (35分鐘)
  AckLog(ackLogId: 11, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 12, 2, 8, 0, 0), responseDateTime: DateTime(2025, 12, 2, 8, 35, 0), isReceived: true,),
  // 12/03 (週三): 錯過 (無回應)
  AckLog(ackLogId: 12, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 12, 3, 8, 0, 0), responseDateTime: null, isReceived: false,),
  // 12/04 (週四): 正常服藥 (8分鐘)
  AckLog(ackLogId: 13, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 12, 4, 8, 0, 0), responseDateTime: DateTime(2025, 12, 4, 8, 8, 0), isReceived: true,),
  // 12/05 (週五 - 今天): 正常服藥 (12分鐘)
  AckLog(ackLogId: 14, alarmId: 101, alarmTitle: '降壓藥', alarmDateTime: DateTime(2025, 12, 5, 8, 0, 0), responseDateTime: DateTime(2025, 12, 5, 8, 12, 0), isReceived: true,),
];
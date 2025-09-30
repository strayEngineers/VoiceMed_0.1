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
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// ✅ Import 現有的模型
import 'alarm_info.dart';
import 'user_model.dart';
import 'font_size.dart';
import 'theme_data.dart';
import 'alarm_helper.dart';

// ========== 患者資料模型（整合 User 和 AlarmInfo）==========
class Patient {
  final String id;
  final String name;
  final String deviceName;
  final String inviteCode; // ✅ 改成邀請碼
  bool isOnline;
  List<AlarmInfo> alarms;
  final List<MedicationRecord> records;

  Patient({
    required this.id,
    required this.name,
    required this.deviceName,
    required this.inviteCode,
    required this.isOnline,
    required this.alarms,
    required this.records,
  });

  factory Patient.fromUser(User user, {
    required String deviceName,
    required bool isOnline,
    required List<AlarmInfo> alarms,
  }) {
    return Patient(
      id: user.id.toString(),
      name: user.username,
      deviceName: deviceName,
      inviteCode: user.inviteCode ?? '',
      isOnline: isOnline,
      alarms: alarms,
      records: [],
    );
  }
}

class MedicationRecord {
  final String date;
  final String time;
  final String medicineName;
  final bool taken;

  MedicationRecord({
    required this.date,
    required this.time,
    required this.medicineName,
    required this.taken,
  });
}

// ========== 全域患者列表（可以被修改）==========
List<Patient> globalPatients = [
  Patient(
    id: "1",
    name: "王小明",
    deviceName: "VoiceMed2-001",
    inviteCode: "12345",
    isOnline: true,
    alarms: [
      AlarmInfo(
        id: 1,
        title: "降血壓藥",
        alarmDateTime: DateTime.now().add(Duration(hours: 1)),
        isEnabled: true,
        isRepeating: true,
        gradientColorIndex: 0,
      ),
      AlarmInfo(
        id: 2,
        title: "胃藥",
        alarmDateTime: DateTime.now().add(Duration(hours: 5)),
        isEnabled: true,
        isRepeating: true,
        gradientColorIndex: 1,
      ),
      AlarmInfo(
        id: 3,
        title: "安眠藥",
        alarmDateTime: DateTime.now().add(Duration(hours: 12)),
        isEnabled: false,
        isRepeating: true,
        gradientColorIndex: 2,
      ),
    ],
    records: [
      MedicationRecord(date: "2025-12-15", time: "08:00", medicineName: "降血壓藥", taken: true),
      MedicationRecord(date: "2025-12-14", time: "20:00", medicineName: "安眠藥", taken: false),
    ],
  ),
  Patient(
    id: "2",
    name: "李奶奶",
    deviceName: "VoiceMed2-002",
    inviteCode: "54321",
    isOnline: true,
    alarms: [
      AlarmInfo(
        id: 4,
        title: "糖尿病藥",
        alarmDateTime: DateTime.now().add(Duration(hours: 2)),
        isEnabled: true,
        isRepeating: true,
        gradientColorIndex: 3,
      ),
      AlarmInfo(
        id: 5,
        title: "維他命",
        alarmDateTime: DateTime.now().add(Duration(hours: 10)),
        isEnabled: true,
        isRepeating: false,
        gradientColorIndex: 4,
      ),
    ],
    records: [
      MedicationRecord(date: "2025-12-15", time: "09:00", medicineName: "糖尿病藥", taken: true),
    ],
  ),
  Patient(
    id: "3",
    name: "張爺爺",
    deviceName: "VoiceMed2-003",
    inviteCode: "99999",
    isOnline: false,
    alarms: [
      AlarmInfo(
        id: 6,
        title: "心臟藥",
        alarmDateTime: DateTime.now().add(Duration(hours: 3)),
        isEnabled: true,
        isRepeating: true,
        gradientColorIndex: 0,
      ),
    ],
    records: [],
  ),
];

// ========== 照護者主頁面 ==========
class CaregiverPage extends StatefulWidget {
  const CaregiverPage({Key? key}) : super(key: key);

  @override
  State<CaregiverPage> createState() => _CaregiverPageState();
}

class _CaregiverPageState extends State<CaregiverPage> {
  bool showOfflineOnly = false;
  final AlarmHelper _alarmHelper = AlarmHelper();

  List<Patient> get filteredPatients {
    if (showOfflineOnly) {
      return globalPatients.where((p) => !p.isOnline).toList();
    }
    return globalPatients;
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLightTheme ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          '照護者模式',
          style: TextStyle(
            fontSize: fontSizeProvider.fontSize + 4,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF439775),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPatientPage(),
                ),
              );
              
              // ✅ 有新增成功時刷新列表
              if (result == true) {
                setState(() {});
              }
            },
            tooltip: '新增被照護者',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('重新載入資料...'), duration: Duration(seconds: 5)),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('資料載入完畢！'), duration: Duration(seconds: 2)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF439775),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showOfflineOnly = false;
                      });
                    },
                    icon: Icon(Icons.people, size: fontSizeProvider.fontSize),
                    label: Text(
                      '全部 (${globalPatients.length})',
                      style: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !showOfflineOnly ? Colors.white : Colors.white.withOpacity(0.3),
                      foregroundColor: !showOfflineOnly ? const Color(0xFF439775) : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showOfflineOnly = true;
                      });
                    },
                    icon: Icon(Icons.error_outline, size: fontSizeProvider.fontSize),
                    label: Text(
                      '離線 (${globalPatients.where((p) => !p.isOnline).length})',
                      style: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showOfflineOnly ? Colors.red : Colors.white.withOpacity(0.3),
                      foregroundColor: showOfflineOnly ? Colors.white : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: filteredPatients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          showOfflineOnly ? '目前沒有離線裝置' : '尚未新增照護對象',
                          style: TextStyle(fontSize: fontSizeProvider.fontSize, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      return _buildPatientCard(patient, fontSizeProvider, isLightTheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patient patient, FontSizeProvider fontSizeProvider, bool isLightTheme) {
    final enabledAlarms = patient.alarms.where((a) => a.isEnabled ?? false).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLightTheme ? Colors.white : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: patient.isOnline ? const Color(0xFF439775) : Colors.red,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (patient.isOnline ? const Color(0xFF439775) : Colors.red).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailPage(patient: patient, alarmHelper: _alarmHelper),
              ),
            ).then((_) {
              setState(() {});
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: patient.isOnline ? const Color(0xFF439775) : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              patient.name,
                              style: TextStyle(
                                fontSize: fontSizeProvider.fontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: patient.isOnline ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              patient.isOnline ? '在線' : '離線',
                              style: TextStyle(
                                fontSize: fontSizeProvider.fontSize - 6,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient.deviceName,
                        style: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 4,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$enabledAlarms/${patient.alarms.length} 個鬧鐘啟用中',
                        style: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 4,
                          color: const Color(0xFF439775),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== 患者詳細頁面 ==========
class PatientDetailPage extends StatefulWidget {
  final Patient patient;
  final AlarmHelper alarmHelper;

  const PatientDetailPage({
    Key? key,
    required this.patient,
    required this.alarmHelper,
  }) : super(key: key);

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  int selectedTabIndex = 0;
  
  // ✅ 新增鬧鐘用的變數
  DateTime? _newAlarmTime;
  late String _newAlarmTimeString;
  bool _newIsRepeatSelected = false;
  final TextEditingController _newTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newAlarmTime = DateTime.now();
    _newAlarmTimeString = DateFormat('HH:mm').format(_newAlarmTime!);
  }

  @override
  void dispose() {
    _newTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLightTheme ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          widget.patient.name,
          style: TextStyle(
            fontSize: fontSizeProvider.fontSize + 4,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF439775),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tab 切換按鈕
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedTabIndex = 0;
                      });
                    },
                    icon: Icon(Icons.alarm, size: fontSizeProvider.fontSize),
                    label: Text('服藥鬧鐘', style: TextStyle(fontSize: fontSizeProvider.fontSize - 2)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedTabIndex == 0 ? const Color(0xFF439775) : Colors.grey[300],
                      foregroundColor: selectedTabIndex == 0 ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: selectedTabIndex == 0 ? 4 : 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedTabIndex = 1;
                      });
                    },
                    icon: Icon(Icons.history, size: fontSizeProvider.fontSize),
                    label: Text('服藥紀錄', style: TextStyle(fontSize: fontSizeProvider.fontSize - 2)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedTabIndex == 1 ? const Color(0xFF439775) : Colors.grey[300],
                      foregroundColor: selectedTabIndex == 1 ? Colors.white : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: selectedTabIndex == 1 ? 4 : 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 內容區域
          Expanded(
            child: selectedTabIndex == 0
                ? _buildAlarmList(fontSizeProvider, isLightTheme)
                : _buildMedicationRecordList(fontSizeProvider, isLightTheme),
          ),
          
          // ✅ 新增鬧鐘按鈕（只在服藥鬧鐘 tab 顯示）
          if (selectedTabIndex == 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLightTheme ? Colors.white : const Color(0xFF1E1E1E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openCreateAlarmSheet,
                  icon: Icon(Icons.add_alarm, size: fontSizeProvider.fontSize),
                  label: Text(
                    '新增鬧鐘',
                    style: TextStyle(
                      fontSize: fontSizeProvider.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF439775),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ 打開新增鬧鐘的 bottom sheet
  void _openCreateAlarmSheet() {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context, listen: false);

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      clipBehavior: Clip.antiAlias,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 標題
                  Text(
                    '新增服藥鬧鐘',
                    style: TextStyle(
                      fontSize: fontSizeProvider.fontSize + 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 選時間
                  TextButton(
                    onPressed: () async {
                      final selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_newAlarmTime!),
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              primaryColor: const Color(0xFF439775),
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF439775),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (selectedTime != null) {
                        final now = DateTime.now();
                        final selectedDateTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        _newAlarmTime = selectedDateTime;
                        setModalState(() {
                          _newAlarmTimeString = DateFormat('HH:mm').format(_newAlarmTime!);
                        });
                      }
                    },
                    child: Text(
                      _newAlarmTimeString,
                      style: TextStyle(
                        fontSize: fontSizeProvider.fontSize + 8,
                        color: const Color(0xFF439775),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 是否每天
                  ListTile(
                    title: Text(
                      '每天重複',
                      style: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
                    ),
                    trailing: Switch(
                      activeTrackColor: const Color(0xFF439775),
                      activeColor: Colors.white,
                      value: _newIsRepeatSelected,
                      onChanged: (value) {
                        setModalState(() {
                          _newIsRepeatSelected = value;
                        });
                      },
                    ),
                  ),

                  // 標題
                  ListTile(
                    title: Text(
                      '提醒內容',
                      style: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
                    ),
                    subtitle: Text(
                      _newTitleController.text.isEmpty ? '點擊輸入' : _newTitleController.text,
                      style: TextStyle(
                        fontSize: fontSizeProvider.fontSize - 3,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: Text(
                              '輸入提醒標題',
                              style: TextStyle(fontSize: fontSizeProvider.fontSize),
                            ),
                            content: TextField(
                              controller: _newTitleController,
                              cursorColor: const Color(0xFF439775),
                              decoration: const InputDecoration(
                                hintText: '例如：晚餐後服用降血壓藥',
                                border: UnderlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setModalState(() {}); // 更新 subtitle
                              },
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                child: Text(
                                  '取消',
                                  style: TextStyle(
                                    color: const Color(0xFF439775),
                                    fontSize: fontSizeProvider.fontSize - 2,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setModalState(() {});
                                  Navigator.of(dialogContext).pop();
                                },
                                child: Text(
                                  '完成',
                                  style: TextStyle(
                                    color: const Color(0xFF439775),
                                    fontSize: fontSizeProvider.fontSize - 2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // 儲存按鈕
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _saveNewAlarm(context),
                      icon: const Icon(Icons.check),
                      label: Text(
                        '儲存鬧鐘',
                        style: TextStyle(
                          fontSize: fontSizeProvider.fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF439775),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ✅ 儲存新鬧鐘
  Future<void> _saveNewAlarm(BuildContext bottomSheetContext) async {
    // 時間往後補一天的邏輯
    DateTime scheduleDateTime;
    _newAlarmTime ??= DateTime.now().add(const Duration(days: 1));
    if (_newAlarmTime!.isAfter(DateTime.now())) {
      scheduleDateTime = _newAlarmTime!;
    } else {
      scheduleDateTime = _newAlarmTime!.add(const Duration(days: 1));
    }

    // 建立新的 AlarmInfo
    final newAlarm = AlarmInfo(
      alarmDateTime: scheduleDateTime,
      gradientColorIndex: widget.patient.alarms.length % 5,
      title: (_newTitleController.text.trim().isNotEmpty)
          ? _newTitleController.text.trim()
          : '服藥提醒',
      isRepeating: _newIsRepeatSelected,
      isEnabled: true,
    );

    // 寫入資料庫
    final insertedId = await widget.alarmHelper.insertAlarm(newAlarm);
    newAlarm.id = insertedId; // 設定ID

    // 加入當前患者的鬧鐘列表
    setState(() {
      widget.patient.alarms.add(newAlarm);
    });

    if (!mounted) return;
    Navigator.of(bottomSheetContext).pop(); // 關閉 bottom sheet

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 已新增服藥鬧鐘'),
        duration: Duration(seconds: 2),
      ),
    );

    // 重置表單
    _newTitleController.clear();
    _newIsRepeatSelected = false;
    _newAlarmTime = DateTime.now();
    _newAlarmTimeString = DateFormat('HH:mm').format(_newAlarmTime!);
  }

  Widget _buildAlarmList(FontSizeProvider fontSizeProvider, bool isLightTheme) {
    if (widget.patient.alarms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alarm_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('尚未設定鬧鐘', style: TextStyle(fontSize: fontSizeProvider.fontSize, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.patient.alarms.length,
      itemBuilder: (context, index) {
        final alarm = widget.patient.alarms[index];
        return _buildAlarmCard(alarm, fontSizeProvider, isLightTheme);
      },
    );
  }

  Widget _buildAlarmCard(AlarmInfo alarm, FontSizeProvider fontSizeProvider, bool isLightTheme) {
    var gradientColor = GradientTemplate.gradientTemplate[alarm.gradientColorIndex! % 5].colors;
    var alarmTime = DateFormat('hh:mm aa').format(alarm.alarmDateTime!);

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('點擊 ${alarm.title} 的鬧鐘'), duration: const Duration(seconds: 1)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColor,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColor.last.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(4, 4),
            ),
          ],
          borderRadius: const BorderRadius.all(Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.label,
                      color: const Color(0xFF2A4747),
                      size: 22 * fontSizeProvider.fontSize / 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      alarm.title ?? '提醒',
                      style: TextStyle(
                        color: const Color(0xFF2A4747),
                        fontSize: fontSizeProvider.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Switch(
                  onChanged: (bool value) async {
                    setState(() {
                      alarm.isEnabled = value;
                    });
                    
                    await widget.alarmHelper.updateAlarm(alarm);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value ? '已啟用鬧鐘' : '已停用鬧鐘'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  value: alarm.isEnabled ?? false,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF439775),
                ),
              ],
            ),
            Text(
              alarm.isRepeating == true ? '每天' : '',
              style: TextStyle(
                color: const Color(0xFF2A4747),
                fontSize: fontSizeProvider.fontSize - 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              alarmTime,
              style: TextStyle(
                color: const Color(0xFF2A4747),
                fontSize: fontSizeProvider.fontSize + 4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationRecordList(FontSizeProvider fontSizeProvider, bool isLightTheme) {
    if (widget.patient.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('尚無服藥紀錄', style: TextStyle(fontSize: fontSizeProvider.fontSize, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.patient.records.length,
      itemBuilder: (context, index) {
        final record = widget.patient.records[index];
        return _buildRecordCard(record, fontSizeProvider, isLightTheme);
      },
    );
  }

  Widget _buildRecordCard(MedicationRecord record, FontSizeProvider fontSizeProvider, bool isLightTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLightTheme ? Colors.white : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: record.taken ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: record.taken ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              record.taken ? Icons.check_circle : Icons.cancel,
              color: record.taken ? Colors.green : Colors.red,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.medicineName,
                  style: TextStyle(fontSize: fontSizeProvider.fontSize, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: fontSizeProvider.fontSize - 4, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${record.date} ${record.time}',
                      style: TextStyle(fontSize: fontSizeProvider.fontSize - 4, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  record.taken ? '已服藥' : '未服藥',
                  style: TextStyle(
                    fontSize: fontSizeProvider.fontSize - 4,
                    color: record.taken ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== 新增被照護者頁面 ==========
class AddPatientPage extends StatefulWidget {
  const AddPatientPage({Key? key}) : super(key: key);

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _patientNameController.dispose();
    super.dispose();
  }

  // ✅ 防呆並送出邀請
  Future<void> _addPatient() async {
    // 驗證表單
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final inviteCode = _inviteCodeController.text.trim();
    final patientName = _patientNameController.text.trim();

    // 顯示連接中的提示
    setState(() {
      _isLoading = true;
    });

    // 顯示連接提示對話框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF439775)),
            ),
            SizedBox(height: 16),
            Text(
              '正在發送邀請給 $patientName...',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '等待對方確認中',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    // ✅ 模擬 3 秒延遲（等待對方確認）
    await Future.delayed(Duration(seconds: 3));

    if (!mounted) return;

    // 關閉連接提示
    Navigator.of(context).pop();

    // ✅ 新增被照護者到列表
    final newPatient = Patient(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: patientName,
      deviceName: "VoiceMed2-${(globalPatients.length + 1).toString().padLeft(3, '0')}",
      inviteCode: inviteCode,
      isOnline: true, // 預設為在線
      alarms: [], // 初始沒有鬧鐘
      records: [],
    );

    globalPatients.add(newPatient);

    setState(() {
      _isLoading = false;
    });

    // ✅ 顯示成功訊息
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('連結成功'),
          ],
        ),
        content: Text(
          '已成功連結被照護者：$patientName\n邀請碼：$inviteCode',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 關閉成功對話框
              Navigator.of(context).pop(true); // 返回照護者頁面並刷新
            },
            child: Text(
              '確定',
              style: TextStyle(
                color: Color(0xFF439775),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLightTheme ? const Color(0xFFF5F5F5) : const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          '新增被照護者',
          style: TextStyle(
            fontSize: fontSizeProvider.fontSize + 4,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF439775),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 說明卡片
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF439775).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF439775).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF439775)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '請輸入被照護者提供的邀請碼\n對方確認後即可建立連結',
                        style: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 2,
                          color: const Color(0xFF439775),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 被照護者姓名
              Text(
                '被照護者姓名',
                style: TextStyle(
                  fontSize: fontSizeProvider.fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _patientNameController,
                style: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
                decoration: InputDecoration(
                  hintText: '例如：王小明',
                  hintStyle: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF439775)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF439775), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '❌ 請輸入被照護者姓名';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // 邀請碼
              Text(
                '邀請碼',
                style: TextStyle(
                  fontSize: fontSizeProvider.fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _inviteCodeController,
                style: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '例如：12345',
                  hintStyle: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
                  prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF439775)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF439775), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '❌ 請輸入邀請碼';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 40),
              
              // 送出按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addPatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF439775),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(
                      fontSize: fontSizeProvider.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('建立連結'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

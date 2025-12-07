import 'dart:async';
import 'dart:convert'; // 用於 utf8 encode
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiSetupPage extends StatefulWidget {
  const WifiSetupPage({super.key});

  @override
  State<WifiSetupPage> createState() => _WifiSetupPageState();
}

class _WifiSetupPageState extends State<WifiSetupPage> {
  // 1. 定義從 .ino 檔案分析出來的 UUID
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHAR_WIFI_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // 狀態變數
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  bool isConnecting = false;
  
  // 輸入框控制器
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 訂閱物件 (用於銷毀頁面時取消監聽)
  StreamSubscription? _scanSubscription;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 步驟 1: 開始掃描
  Future<void> startScan() async {
    // 先檢查權限 (Android 12+ 需要)
    bool permGranted = await _checkPermissions();
    if (!permGranted) {
      _showSnackBar("請允許藍牙與位置權限以進行掃描");
      return;
    }

    setState(() {
      isScanning = true;
      scanResults.clear(); // 清空舊列表
    });

    // 監聽掃描結果
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        // 過濾條件：只顯示有名稱的裝置，或者你要過濾特定的 Service UUID
        scanResults = results.where((r) => r.device.platformName.isNotEmpty).toList();
      });
    });

    // 啟動掃描 (5秒後自動停止)
    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        // androidUsesFineLocation: true, // 視情況開啟
      );
    } catch (e) {
      _showSnackBar("掃描啟動失敗: $e");
    }

    // 等待掃描結束
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      setState(() {
        isScanning = false;
      });
    }
  }

  // 步驟 2 & 3: 連線並寫入 WiFi 資料
  Future<void> connectAndSendWifi(BluetoothDevice device) async {
    // 防呆
    if (_ssidController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("請先輸入 WiFi 名稱與密碼");
      return;
    }

    setState(() => isConnecting = true);

    try {
      // 1. 連線
      await device.connect(timeout: const Duration(seconds: 5));
      
      // 2. 發現服務 (Discover Services)
      List<BluetoothService> services = await device.discoverServices();
      
      // 3. 找到目標服務
      BluetoothService? targetService;
      try {
        targetService = services.firstWhere((s) => s.uuid.toString() == SERVICE_UUID);
      } catch (e) {
        throw "找不到 VoiceMed 服務，請確認這是正確的裝置";
      }

      // 4. 找到寫入特徵 (Characteristic)
      BluetoothCharacteristic? targetChar;
      try {
        targetChar = targetService.characteristics.firstWhere((c) => c.uuid.toString() == CHAR_WIFI_UUID);
      } catch (e) {
        throw "找不到 WiFi 設定特徵";
      }

      // 5. 組合資料 (依照 .ino 的邏輯：SSID,Password)
      String dataToSend = "${_ssidController.text},${_passwordController.text}";
      
      // 6. 寫入資料
      await targetChar.write(utf8.encode(dataToSend));
      
      _showSnackBar("設定成功！藥盒正在連線 WiFi...");
      
      // 7. 斷線 (讓藥盒可以專心連 WiFi)
      await device.disconnect();

    } catch (e) {
      _showSnackBar("操作失敗: $e");
    } finally {
      if (mounted) {
        setState(() => isConnecting = false);
      }
    }
  }

  // 權限檢查 helper
  Future<bool> _checkPermissions() async {
    // 簡單檢查，實際專案建議用 permission_handler 做更完整的請求
    var status = await Permission.bluetoothScan.status;
    if (!status.isGranted) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.location.request(); // Android 需要位置權限才能掃描
    }
    return true;
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("藥盒配網設定")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // WiFi 輸入區
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(
                labelText: "WiFi 名稱 (SSID)",
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "WiFi 密碼",
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            
            // 掃描按鈕
            ElevatedButton.icon(
              onPressed: isScanning || isConnecting ? null : startScan,
              icon: isScanning 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.search),
              label: Text(isScanning ? "掃描中..." : "掃描附近藥盒"),
            ),
            
            const Divider(height: 30),
            
            // 裝置列表
            Expanded(
              child: scanResults.isEmpty
                  ? const Center(child: Text("尚未發現裝置，請按掃描"))
                  : ListView.builder(
                      itemCount: scanResults.length,
                      itemBuilder: (context, index) {
                        final result = scanResults[index];
                        return Card(
                          child: ListTile(
                            title: Text(result.device.platformName.isNotEmpty 
                                ? result.device.platformName 
                                : "未命名裝置"),
                            subtitle: Text(result.device.remoteId.toString()), // MAC Address
                            trailing: ElevatedButton(
                              onPressed: isConnecting 
                                  ? null 
                                  : () => connectAndSendWifi(result.device),
                              child: const Text("寫入設定"),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

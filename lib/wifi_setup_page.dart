import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'font_size.dart';

class WifiSetupPage extends StatefulWidget {
  const WifiSetupPage({super.key});

  @override
  State<WifiSetupPage> createState() => _WifiSetupPageState();
}

class _WifiSetupPageState extends State<WifiSetupPage> {
  // UUID 定義
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHAR_WIFI_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String CHAR_STATUS_UUID = "c5c5c001-4e00-4740-98d0-25032906e001";

  // 狀態變數
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  bool isConnecting = false;
  String connectionStatus = "尚未連線";
  
  // 輸入框控制器
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // 訂閱物件
  StreamSubscription? _scanSubscription;
  BluetoothDevice? _connectedDevice;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _ssidController.dispose();
    _passwordController.dispose();
    _connectedDevice?.disconnect();
    super.dispose();
  }

  // 開始掃描藍牙裝置
  Future<void> startScan() async {
    bool permGranted = await _checkPermissions();
    if (!permGranted) {
      _showSnackBar("請允許藍牙與位置權限以進行掃描");
      return;
    }

    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        // ✅ 使用 name 而不是 platformName（1.14.8 版本）
        // scanResults = results.where((r) => r.device.name.isNotEmpty).toList();
        scanResults = results; // fixing ble scan issue

        // ✅ 在 Console 印出所有裝置資訊
        for (var r in results) {
          print("🔍 發現裝置:");
          print("  名稱: ${r.device.name.isEmpty ? '(無名稱)' : r.device.name}");
          print("  ID: ${r.device.id}");
          print("  RSSI: ${r.rssi}");
          print("  Services: ${r.advertisementData.serviceUuids}");
        }
      });
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,  // ✅ Android 12+ 必要
      );
    } catch (e) {
      _showSnackBar("掃描啟動失敗: $e");
      print("❌ 掃描錯誤: $e");
    }

    await Future.delayed(const Duration(seconds: 10));
    if (mounted) {
      setState(() {
        isScanning = false;
      });
    }
  }

  // 連線並傳送 WiFi 設定
  Future<void> connectAndSendWifi(BluetoothDevice device) async {
    if (_ssidController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("請先輸入 WiFi 名稱與密碼");
      return;
    }

    setState(() {
      isConnecting = true;
      connectionStatus = "正在連線藍牙...";
    });

    try {
      // 1. 連線裝置
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      
      setState(() {
        connectionStatus = "藍牙已連線，正在發現服務...";
      });

      // 2. 發現服務
      List<BluetoothService> services = await device.discoverServices();

      // 3. 找到目標服務
      BluetoothService? targetService;
      try {
        targetService = services.firstWhere(
          (s) => s.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()
        );
      } catch (e) {
        throw "找不到 VoiceMed 服務，請確認這是正確的裝置";
      }

      // 4. 找到特徵
      BluetoothCharacteristic? wifiChar;
      BluetoothCharacteristic? statusChar;
      
      try {
        wifiChar = targetService.characteristics.firstWhere(
          (c) => c.uuid.toString().toLowerCase() == CHAR_WIFI_UUID.toLowerCase()
        );
        
        // 嘗試找狀態特徵（如果ESP32端已實作）
        try {
          statusChar = targetService.characteristics.firstWhere(
            (c) => c.uuid.toString().toLowerCase() == CHAR_STATUS_UUID.toLowerCase()
          );
        } catch (e) {
          print("狀態特徵未找到，將使用簡化流程");
        }
      } catch (e) {
        throw "找不到 WiFi 設定特徵";
      }

      setState(() {
        connectionStatus = "正在傳送 WiFi 設定...";
      });

      // 5. 訂閱狀態通知（如果有）
      if (statusChar != null) {
        await statusChar.setNotifyValue(true);
        statusChar.value.listen((value) {
          if (value.isNotEmpty) {
            String status = utf8.decode(value);
            setState(() => connectionStatus = status);

            if (status.startsWith("CONNECTED:")) {
              String ip = status.split(":").length > 1 ? status.split(":")[1] : "未知";
              // ✅ 使用 name 而不是 platformName
              _saveConnectionInfo(device.name, ip);
              _showSnackBar("✅ WiFi 連線成功！IP: $ip");
              
              // 延遲後斷線並返回
              Future.delayed(Duration(seconds: 2), () {
                device.disconnect();
                Navigator.pop(context, true);
              });
            }
          }
        });
      }

      // 6. 寫入 WiFi 憑證
      String dataToSend = "${_ssidController.text},${_passwordController.text}";
      await wifiChar.write(utf8.encode(dataToSend));

      setState(() {
        connectionStatus = "設定已傳送，等待藥盒連線 WiFi...";
      });

      // 7. 如果沒有狀態特徵，等待30秒後提示
      if (statusChar == null) {
        await Future.delayed(const Duration(seconds: 30));
        if (mounted) {
          _showSnackBar("⏰ 已傳送設定，請確認藥盒螢幕顯示連線狀態");
          await device.disconnect();
          Navigator.pop(context, false);
        }
      }

    } catch (e) {
      _showSnackBar("操作失敗: $e");
      await device.disconnect();
    } finally {
      if (mounted) {
        setState(() {
          isConnecting = false;
        });
      }
    }
  }

  // 儲存連線資訊
  Future<void> _saveConnectionInfo(String deviceName, String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32_device_name', deviceName);
    await prefs.setString('esp32_ip', ip);
  }

  // 權限檢查
  Future<bool> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    if (!allGranted) {
      _showSnackBar("請在設定中允許所有必要權限");
    }
    
    return allGranted;
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "藥盒配網設定",
          style: TextStyle(
            fontSize: fontSizeProvider.fontSize + 6,
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF439775),
        iconTheme: IconThemeData(
          color: Color(0xFFEFF7CF),
          size: 30 * fontSizeProvider.fontSize / 20,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 步驟指示器
                _buildStepIndicator(fontSizeProvider),
                
                SizedBox(height: 20),
                
                // WiFi 輸入區
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "步驟 1: 輸入 WiFi 資訊",
                          style: TextStyle(
                            fontSize: fontSizeProvider.fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          controller: _ssidController,
                          decoration: InputDecoration(
                            labelText: "WiFi 名稱 (SSID)",
                            labelStyle: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
                            prefixIcon: Icon(Icons.wifi),
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(fontSize: fontSizeProvider.fontSize),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: "WiFi 密碼",
                            labelStyle: TextStyle(fontSize: fontSizeProvider.fontSize - 2),
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          style: TextStyle(fontSize: fontSizeProvider.fontSize),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 15),
                
                // 連線狀態顯示
                if (connectionStatus != "尚未連線")
                  Card(
                    color: connectionStatus.contains("成功") || connectionStatus.startsWith("CONNECTED")
                        ? Colors.green[50]
                        : Colors.blue[50],
                    child: ListTile(
                      leading: Icon(
                        connectionStatus.contains("成功") || connectionStatus.startsWith("CONNECTED")
                            ? Icons.check_circle
                            : Icons.info,
                        color: connectionStatus.contains("成功") || connectionStatus.startsWith("CONNECTED")
                            ? Colors.green
                            : Colors.blue,
                      ),
                      title: Text(
                        "連線狀態",
                        style: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        connectionStatus,
                        style: TextStyle(fontSize: fontSizeProvider.fontSize - 3),
                      ),
                    ),
                  ),
                
                SizedBox(height: 15),
                
                // 掃描按鈕
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isScanning || isConnecting ? null : startScan,
                    icon: isScanning
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.search),
                    label: Text(
                      isScanning ? "掃描中..." : "步驟 2: 掃描藥盒",
                      style: TextStyle(fontSize: fontSizeProvider.fontSize),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF439775),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                
                Divider(height: 30),
                
                // 裝置列表
                _buildDeviceList(fontSizeProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 步驟指示器
  Widget _buildStepIndicator(FontSizeProvider fontSizeProvider) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "請確保藥盒已開機並處於配對模式",
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize - 3,
                color: Colors.amber[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(FontSizeProvider fontSizeProvider) {
    if (scanResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 60 * fontSizeProvider.fontSize / 20,
              color: Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              "尚未發現裝置\n請按「掃描藥盒」按鈕",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize - 2,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: scanResults.length,
      shrinkWrap: true,                          // ✅ 高度由內容決定，配合外層 ScrollView
      physics: const NeverScrollableScrollPhysics(), // ✅ 不自己捲動，交給外層 SingleChildScrollView
      itemBuilder: (context, index) {
        final result = scanResults[index];

        // ✅ 檢查是否是 VoiceMed 裝置
        final isVoiceMed = result.advertisementData.serviceUuids.any(
          (uuid) => uuid.toString().toLowerCase().contains("4fafc201")
        );
        
        // ✅ 顯示名稱（空名稱也顯示）
        final deviceName = result.device.name.isNotEmpty 
            ? result.device.name 
            : isVoiceMed ? "VoiceMed 藥盒 (未命名)" : "(未命名)";

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isVoiceMed ? Colors.green[50] : null,  // ✅ VoiceMed 用綠色背景
          child: ListTile(
            leading: Icon(
              Icons.devices,
              color: const Color(0xFF439775),
              size: 30 * fontSizeProvider.fontSize / 20,
            ),
            title: Text(
              result.device.name.isNotEmpty ? result.device.name : "未命名裝置",
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              result.device.id.toString(),
              style: TextStyle(
                fontSize: fontSizeProvider.fontSize - 4,
              ),
            ),
            trailing: ElevatedButton(
              onPressed: isConnecting ? null : () => connectAndSendWifi(result.device),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF439775),
                foregroundColor: Colors.white,
              ),
              child: Text(
                "連接",
                style: TextStyle(
                  fontSize: fontSizeProvider.fontSize - 4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}

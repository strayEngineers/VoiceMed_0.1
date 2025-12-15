// ignore_for_file: prefer_const_constructors, use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'font_size.dart';

class DeviceConnectionPage extends StatefulWidget {
  const DeviceConnectionPage({Key? key}) : super(key: key);

  @override
  _DeviceConnectionPageState createState() => _DeviceConnectionPageState();
}

class _DeviceConnectionPageState extends State<DeviceConnectionPage> {
  String? connectedDeviceName;
  String? connectedDeviceIP;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadConnectionStatus();

    // ✅ 自動設定為已連線（因為 ESP32 寫死 WiFi）
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        connectedDeviceName = "VoiceMed2 (固定配置)";
        connectedDeviceIP = "192.168.x.x";  // ← 從 ESP32 Serial Monitor 複製實際 IP
        isConnected = true;
      });
    });
  }

  Future<void> _loadConnectionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      connectedDeviceName = prefs.getString('esp32_device_name');
      connectedDeviceIP = prefs.getString('esp32_ip');
      isConnected = connectedDeviceIP != null && connectedDeviceIP!.isNotEmpty;
    });
  }

  Future<void> _disconnectDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('esp32_device_name');
    await prefs.remove('esp32_ip');
    
    setState(() {
      connectedDeviceName = null;
      connectedDeviceIP = null;
      isConnected = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已中斷藥盒連線')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '藥盒連接',
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
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 連線狀態卡片
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isConnected ? Colors.green[50] : Colors.grey[100],
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          isConnected 
                              ? Icons.check_circle_outline 
                              : Icons.bluetooth_disabled,
                          size: 60 * fontSizeProvider.fontSize / 20,
                          color: isConnected ? Colors.green : Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Text(
                          isConnected ? '藥盒已連線' : '尚未連接藥盒',
                          style: TextStyle(
                            fontSize: fontSizeProvider.fontSize + 4,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? Colors.green[700] : Colors.grey[700],
                          ),
                        ),
                        if (isConnected) ...[
                          SizedBox(height: 10),
                          Divider(),
                          SizedBox(height: 10),
                          _buildInfoRow(
                            Icons.devices, 
                            '裝置名稱', 
                            connectedDeviceName ?? '未知裝置',
                            fontSizeProvider
                          ),
                          SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.wifi, 
                            'IP 位址', 
                            connectedDeviceIP ?? '未知',
                            fontSizeProvider
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 30),
                
                // 連接新裝置按鈕
                ElevatedButton.icon(
                  onPressed: () async {
                    // 導航至 WiFi 設定頁面
                    final result = await Navigator.pushNamed(context, '/wifiSetup');
                    if (result == true) {
                      // 連接成功後重新載入狀態
                      _loadConnectionStatus();
                    }
                  },
                  icon: Icon(
                    Icons.add_circle_outline, 
                    size: 24 * fontSizeProvider.fontSize / 20,
                  ),
                  label: Text(
                    isConnected ? '連接新裝置' : '開始配對',
                    style: TextStyle(fontSize: fontSizeProvider.fontSize),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF439775),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                if (isConnected) ...[
                  SizedBox(height: 15),
                  // 中斷連線按鈕
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            '中斷連線',
                            style: TextStyle(fontSize: fontSizeProvider.fontSize + 2),
                          ),
                          content: Text(
                            '確定要中斷與藥盒的連線嗎？',
                            style: TextStyle(fontSize: fontSizeProvider.fontSize),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('取消'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _disconnectDevice();
                              },
                              child: Text(
                                '確定',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.link_off, size: 24 * fontSizeProvider.fontSize / 20),
                    label: Text(
                      '中斷連線',
                      style: TextStyle(fontSize: fontSizeProvider.fontSize),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: 30),
                
                // 說明文字
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          SizedBox(width: 8),
                          Text(
                            '連接步驟說明',
                            style: TextStyle(
                              fontSize: fontSizeProvider.fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        '1. 確保藥盒已開機並處於藍牙配對模式\n'
                        '2. 點擊「開始配對」按鈕\n'
                        '3. 掃描並選擇您的藥盒裝置\n'
                        '4. 輸入家中 WiFi 的帳號密碼\n'
                        '5. 等待藥盒連線至網路',
                        style: TextStyle(
                          fontSize: fontSizeProvider.fontSize - 2,
                          color: Colors.blue[900],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon, 
    String label, 
    String value,
    FontSizeProvider fontSizeProvider
  ) {
    return Row(
      children: [
        Icon(icon, size: 20 * fontSizeProvider.fontSize / 20, color: Colors.green[700]),
        SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: fontSizeProvider.fontSize - 2,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: fontSizeProvider.fontSize - 2,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'database_helper.dart'; // 引入資料庫操作
// ignore: unused_import
import 'user_model.dart'; // 引入使用者模型 (雖然這頁面主要只用到屬性，但保持引用是好習慣)

class AddPatientPage extends StatefulWidget {
  // 【關鍵補充】我們需要知道現在是「哪位照護者」要新增病人
  // 這個 id 會從上一頁 (CaregiverHomePage) 傳進來
  final int caregiverId;

  const AddPatientPage({
    super.key, 
    required this.caregiverId
  });

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  // 使用 Controller 管理輸入框
  final TextEditingController _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _addPatient() async {
    // 取得輸入並去除前後空白
    final inviteCode = _inviteCodeController.text.trim();

    // 1. 基本防呆
    if (inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請輸入邀請碼")),
      );
      return;
    }

    // 2. 查詢該邀請碼對應的使用者
    final patient = await DatabaseHelper.instance.getUserByInviteCode(inviteCode);

    // 確保查詢回來後頁面還在
    if (!mounted) return;

    // 3. 驗證邏輯
    if (patient != null && patient.role == 'patient') {
      // 3-1. 檢查是否已經連結過 (選擇性功能，目前先省略，直接連結)
      // 如果要更嚴謹，可以在這裡先 query care_relationships 表看是否已存在

      // 3-2. 寫入資料庫
      await DatabaseHelper.instance.addCareRelationship(
        caregiverId: widget.caregiverId, // 使用從上一頁傳進來的 ID
        patientId: patient.id!, // 因為從 DB 抓出來的，id 一定存在
      );

      if (!mounted) return;

      // 3-3. 成功提示並返回上一頁
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("成功連結被照護者：${patient.username}")),
      );
      
      // 返回上一頁，並回傳 true 代表有更新資料，讓上一頁刷新列表
      Navigator.pop(context, true); 

    } else {
      // 失敗提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("邀請碼錯誤，或該帳號不是被照護者身分")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("新增被照護者"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "請輸入被照護者的邀請碼：",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "請被照護者至「個人設定」查看他們的邀請碼。",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // 輸入框
            TextField(
              controller: _inviteCodeController,
              decoration: const InputDecoration(
                labelText: "邀請碼",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
                hintText: "例如：12345",
              ),
              keyboardType: TextInputType.number, // 假設邀請碼是數字，若有英文可拿掉這行
            ),
            const SizedBox(height: 30),
            
            // 送出按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addPatient,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text("建立連結"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

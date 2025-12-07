import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'database_helper.dart'; 
import 'user_model.dart'; 


// 註冊時需選擇角色
enum UserRole { caregiver, patient }
// ...

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.patient;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      // 顯示底部提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("帳號或密碼不能為空！"),
          duration: Duration(seconds: 2), // 顯示 2 秒
        ),
      );
      return;
    }

    // 密碼用 hash 儲存
    final passwordHash = sha256.convert(utf8.encode(password)).toString();
    // inviteCode 只給 patient
    final inviteCode = _selectedRole == UserRole.patient ? _generateInviteCode() : null;

    final newUser = User(
      username: username,
      passwordHash: passwordHash,
      role: _selectedRole.name,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertUser(newUser);
    // 確保頁面還在，才進行路由跳轉
    if (!mounted) return;
    // 註冊後自動登入
    Navigator.pushReplacementNamed(context, '/home');
  }

  String _generateInviteCode() {
    // 建議用 UUID 或亂數字母
    return DateTime.now().millisecondsSinceEpoch.toString().substring(5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("註冊帳號")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 帳號輸入框
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "帳號"),
              ),
              const SizedBox(height: 10),
              
              // 密碼輸入框
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "密碼"),
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // 角色選擇 (Radio Button)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("請選擇您的身分：", style: TextStyle(fontSize: 16)),
              ),
              RadioListTile<UserRole>(
                title: const Text("被照護者 (使用者)"),
                value: UserRole.patient,
                groupValue: _selectedRole,
                onChanged: (UserRole? value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              RadioListTile<UserRole>(
                title: const Text("照護者 (管理藥盒)"),
                value: UserRole.caregiver,
                groupValue: _selectedRole,
                onChanged: (UserRole? value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 20),

              // 註冊按鈕
              ElevatedButton(
                onPressed: _register, // 在這裡呼叫函式
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // 讓按鈕滿寬
                ),
                child: const Text("註冊"),
              ), 
            ],
          ),
        ),
      ),
    );
  }
}


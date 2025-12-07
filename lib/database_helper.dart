// lib/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:voice_med/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('voicemed.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. 使用者帳號表
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL,
        role TEXT NOT NULL,
        inviteCode TEXT UNIQUE,
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. 照護關係表
    await db.execute('''
      CREATE TABLE care_relationships (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        caregiverId INTEGER NOT NULL,
        patientId INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (caregiverId) REFERENCES users(id),
        FOREIGN KEY (patientId) REFERENCES users(id)
      )
    ''');

    // 3. 藥盒裝置表
    await db.execute('''
      CREATE TABLE devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceId TEXT UNIQUE NOT NULL,
        patientId INTEGER NOT NULL,
        deviceName TEXT,
        status TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES users(id)
      )
    ''');

    // 4. 鬧鐘表
    await db.execute('''
      CREATE TABLE alarms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER NOT NULL,
        deviceId INTEGER,
        time TEXT NOT NULL,
        repeatDays TEXT,
        medicineName TEXT,
        isActive INTEGER DEFAULT 1,
        createdBy INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES users(id),
        FOREIGN KEY (deviceId) REFERENCES devices(id),
        FOREIGN KEY (createdBy) REFERENCES users(id)
      )
    ''');

    // 5. 服藥紀錄表
    await db.execute('''
      CREATE TABLE medication_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER NOT NULL,
        alarmId INTEGER,
        deviceId INTEGER,
        takenAt TEXT NOT NULL,
        status TEXT,
        source TEXT,
        FOREIGN KEY (patientId) REFERENCES users(id),
        FOREIGN KEY (alarmId) REFERENCES alarms(id),
        FOREIGN KEY (deviceId) REFERENCES devices(id)
      )
    ''');
  }

  // --- User 相關操作 ---

  // 新增使用者
  Future<User> insertUser(User user) async {
    final db = await instance.database;
    final id = await db.insert('users', user.toMap());
    return user.copy(id: id); // 需在 User model 裡加 copy 方法，或是忽略這行直接回傳
  }

  // 透過帳號名稱取得使用者 (登入用)
  Future<User?> getUserByUsername(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: null, // 查詢所有欄位
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // 透過邀請碼取得使用者 (連結帳號用)
  Future<User?> getUserByInviteCode(String code) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'inviteCode = ?',
      whereArgs: [code],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // 建立照護關係
  Future<void> addCareRelationship({required int caregiverId, required int patientId}) async {
    final db = await instance.database;
    await db.insert('care_relationships', {
      'caregiverId': caregiverId,
      'patientId': patientId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
  
  // 關閉資料庫
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

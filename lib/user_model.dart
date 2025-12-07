class User {
  final int? id;
  final String username;
  final String passwordHash; // 密碼請用 hash 儲存
  final String role; // 'caregiver' 或 'patient'
  final String? inviteCode; // 被照護者用於帳號連結
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.inviteCode,
    required this.createdAt,
  });

  // 將值放入db
  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'passwordHash': passwordHash,
    'role': role,
    'inviteCode': inviteCode,
    'createdAt': createdAt.toIso8601String(),
  };

  // 從db取出值
  static User fromMap(Map<String, dynamic> map) => User(
    id: map['id'],
    username: map['username'],
    passwordHash: map['passwordHash'],
    role: map['role'],
    inviteCode: map['inviteCode'],
    createdAt: DateTime.parse(map['createdAt']),
  );

  User copy({
    int? id,
    String? username,
    String? passwordHash,
    String? role,
    String? inviteCode,
    DateTime? createdAt,
  }) =>
    User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
    );

}

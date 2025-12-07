class Device {
  final int? id;
  final String deviceId; // ESP32唯一識別
  final int patientId;
  final String? deviceName;
  final String status;
  final DateTime createdAt;

  Device({
    this.id,
    required this.deviceId,
    required this.patientId,
    this.deviceName,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'deviceId': deviceId,
    'patientId': patientId,
    'deviceName': deviceName,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  static Device fromMap(Map<String, dynamic> map) => Device(
    id: map['id'],
    deviceId: map['deviceId'],
    patientId: map['patientId'],
    deviceName: map['deviceName'],
    status: map['status'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}

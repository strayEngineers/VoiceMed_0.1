// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_super_parameters, use_build_context_synchronously, library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations, unused_element, use_key_in_widget_constructors, annotate_overrides, avoid_print

class AlarmInfo {
  int? id;
  String? title;
  DateTime? alarmDateTime;
  bool? isRepeating;
  bool? isEnabled;
  int? gradientColorIndex;

  AlarmInfo(
      {this.id,
      this.title,
      this.alarmDateTime,
      this.isRepeating,
      this.isEnabled,
      this.gradientColorIndex});


  // 從db取出值
  factory AlarmInfo.fromMap(Map<String, dynamic> json) => AlarmInfo(
        id: json["id"],
        title: json["title"],
        alarmDateTime: DateTime.parse(json["alarmDateTime"]),
        isRepeating: json['isRepeating'] == 1,
        isEnabled: json['isEnabled'] == 1,
        gradientColorIndex: json["gradientColorIndex"],
      );

  // 將值放入db
  Map<String, dynamic> toMap() => {
        "id": id,
        "title": title,
        "alarmDateTime": alarmDateTime?.toIso8601String(),
        "isRepeating": isRepeating == true ? 1 : 0,
        "isEnabled": isEnabled == true ? 1 : 0,
        "gradientColorIndex": gradientColorIndex,
      };
}

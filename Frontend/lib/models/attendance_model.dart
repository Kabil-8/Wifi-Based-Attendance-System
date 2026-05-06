class AttendanceModel {
  final String date;
  final bool present;

  AttendanceModel({
    required this.date,
    required this.present,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      date: json['date'] ?? '',
      present: json['present'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'present': present,
    };
  }
}

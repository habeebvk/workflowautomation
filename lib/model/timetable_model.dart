class TimetableEntry {
  final int? id;
  final String day;
  final int period;
  final String teacherName;
  final String subject;
  final String className;
  final String startTime;
  final String endTime;
  final String attendance; // "Present" or "Absent"

  TimetableEntry({
    this.id,
    required this.day,
    required this.period,
    required this.teacherName,
    required this.subject,
    required this.className,
    required this.startTime,
    required this.endTime,
    this.attendance = "Present",
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'period': period,
      'teacherName': teacherName,
      'subject': subject,
      'className': className,
      'startTime': startTime,
      'endTime': endTime,
      'attendance': attendance,
    };
  }

  // Create from Map (database retrieval)
  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      id: map['id'],
      day: map['day'],
      period: map['period'],
      teacherName: map['teacherName'],
      subject: map['subject'],
      className: map['className'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      attendance: map['attendance'] ?? "Present",
    );
  }

  // Create a copy with modified fields
  TimetableEntry copyWith({
    int? id,
    String? day,
    int? period,
    String? teacherName,
    String? subject,
    String? className,
    String? startTime,
    String? endTime,
    String? attendance,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      day: day ?? this.day,
      period: period ?? this.period,
      teacherName: teacherName ?? this.teacherName,
      subject: subject ?? this.subject,
      className: className ?? this.className,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      attendance: attendance ?? this.attendance,
    );
  }

  @override
  String toString() {
    return 'TimetableEntry{day: $day, period: $period, teacher: $teacherName, subject: $subject, class: $className, attendance: $attendance}';
  }
}

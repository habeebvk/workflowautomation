class NotificationModel {
  final int? id;
  final String title;
  final String message;
  final String date;
  final String type; // 'note', 'activity', 'answer', 'substitution'

  NotificationModel({
    this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'date': date,
      'type': type,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      date: map['date'],
      type: map['type'],
    );
  }
}

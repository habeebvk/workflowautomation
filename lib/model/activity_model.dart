class ActivityModel {
  final int? id;
  final String teacher;
  final String subject;
  final String question;
  final String date;
  final bool isBookmarked;

  ActivityModel({
    this.id,
    required this.teacher,
    required this.subject,
    required this.question,
    required this.date,
    this.isBookmarked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacher': teacher,
      'subject': subject,
      'question': question,
      'date': date,
      'is_bookmarked': isBookmarked ? 1 : 0,
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'],
      teacher: map['teacher'],
      subject: map['subject'],
      question: map['question'],
      date: map['date'],
      isBookmarked: map['is_bookmarked'] == 1,
    );
  }
}

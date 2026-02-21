class NoteData {
  final int? id;
  final String subject;
  final String teacher;
  final String semester;
  final String content;
  final String? pdfPath;
  final bool isBookmarked;

  NoteData({
    this.id,
    required this.subject,
    required this.teacher,
    required this.semester,
    required this.content,
    this.pdfPath,
    this.isBookmarked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'teacher': teacher,
      'semester': semester,
      'content': content,
      'pdf_path': pdfPath,
      'is_bookmarked': isBookmarked ? 1 : 0,
    };
  }

  factory NoteData.fromMap(Map<String, dynamic> map) {
    return NoteData(
      id: map['id'],
      subject: map['subject'],
      teacher: map['teacher'],
      semester: map['semester'],
      content: map['content'],
      pdfPath: map['pdf_path'],
      isBookmarked: map['is_bookmarked'] == 1,
    );
  }

  static List<NoteData> mockNotes = [
    NoteData(
      subject: "Java",
      teacher: "Sharina",
      semester: "Sem 2",
      content:
          "Java is a high-level, class-based, object-oriented programming language that is designed to have as few implementation dependencies as possible.",
    ),
    NoteData(
      subject: "Python",
      teacher: "Arun",
      semester: "Sem 3",
      content:
          "Python is a high-level, general-purpose programming language. Its design philosophy emphasizes code readability with the use of significant indentation.",
    ),
  ];
}

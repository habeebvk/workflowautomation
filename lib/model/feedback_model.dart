class FeedbackModel {
  final int? id;
  final String name;
  final String content;
  final double rating;

  FeedbackModel({
    this.id,
    required this.name,
    required this.content,
    required this.rating,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'content': content, 'rating': rating};
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'],
      name: map['name'],
      content: map['content'],
      rating: map['rating'],
    );
  }
}

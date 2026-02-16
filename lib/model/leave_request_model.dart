class LeaveRequestModel {
  final int? id;
  final String name;
  final String date;
  final String type;
  final String reason;
  final String status; // 'pending', 'approved', 'declined'

  LeaveRequestModel({
    this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.reason,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'type': type,
      'reason': reason,
      'status': status,
    };
  }

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map) {
    return LeaveRequestModel(
      id: map['id'],
      name: map['name'],
      date: map['date'],
      type: map['type'],
      reason: map['reason'],
      status: map['status'] ?? 'pending',
    );
  }
}

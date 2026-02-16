class UserModel {
  final int? id;
  final String name;
  final String identifier; // Can be email or phone
  final String password;
  final String role;

  UserModel({
    this.id,
    required this.name,
    required this.identifier,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'identifier': identifier,
      'password': password,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      identifier: map['identifier'],
      password: map['password'],
      role: map['role'],
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final String? teamId;
  final String role; // 'user' veya 'admin'

  UserModel({
    required this.id,
    required this.email,
    this.teamId,
    this.role = 'user',
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      teamId: data['teamId'],
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'teamId': teamId,
      'role': role,
    };
  }
}

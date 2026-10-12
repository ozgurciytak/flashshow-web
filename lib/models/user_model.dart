class UserModel {
  final String id;
  final String email;
  final String? teamId;
  final String role; // 'user' veya 'admin'
  final bool isSuspended; // Hesabın askıya alınma durumu
  final String? password; // Şifre (yerel saklama ve şifre sıfırlama/kurtarma için)

  UserModel({
    required this.id,
    required this.email,
    this.teamId,
    this.role = 'user',
    this.isSuspended = false,
    this.password,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      teamId: data['teamId'],
      role: data['role'] ?? 'user',
      isSuspended: data['isSuspended'] ?? false,
      password: data['password'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'teamId': teamId,
      'role': role,
      'isSuspended': isSuspended,
      'password': password,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? teamId,
    String? role,
    bool? isSuspended,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      isSuspended: isSuspended ?? this.isSuspended,
      password: password ?? this.password,
    );
  }
}

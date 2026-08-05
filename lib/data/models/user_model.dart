import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.login,
    required super.avatarUrl,
    super.name,
    super.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      login: json['login'] as String,
      avatarUrl: (json['avatar_url'] as String?) ?? '',
      name: json['name'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'login': login,
      'avatar_url': avatarUrl,
      'name': name,
      'bio': bio,
    };
  }
}

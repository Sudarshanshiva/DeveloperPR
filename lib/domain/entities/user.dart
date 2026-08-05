import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String login;
  final String avatarUrl;
  final String? name;
  final String? bio;

  const User({
    required this.id,
    required this.login,
    required this.avatarUrl,
    this.name,
    this.bio,
  });

  @override
  List<Object?> get props => [id, login, avatarUrl, name, bio];
}

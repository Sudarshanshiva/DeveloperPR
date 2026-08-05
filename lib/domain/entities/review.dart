import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final int id;
  final String userLogin;
  final String userAvatar;
  final String state; // 'APPROVED', 'CHANGES_REQUESTED', 'COMMENTED', 'DISMISSED', 'PENDING'
  final String body;
  final DateTime? submittedAt;

  const Review({
    required this.id,
    required this.userLogin,
    required this.userAvatar,
    required this.state,
    required this.body,
    this.submittedAt,
  });

  @override
  List<Object?> get props => [id, userLogin, userAvatar, state, body, submittedAt];
}

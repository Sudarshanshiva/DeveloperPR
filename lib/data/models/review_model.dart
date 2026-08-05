import '../../domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.userLogin,
    required super.userAvatar,
    required super.state,
    required super.body,
    super.submittedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>? ?? {};

    return ReviewModel(
      id: (json['id'] as int?) ?? 0,
      userLogin: (userMap['login'] as String?) ?? 'reviewer',
      userAvatar: (userMap['avatar_url'] as String?) ?? '',
      state: (json['state'] as String?) ?? 'PENDING',
      body: (json['body'] as String?) ?? '',
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': {
        'login': userLogin,
        'avatar_url': userAvatar,
      },
      'state': state,
      'body': body,
      'submitted_at': submittedAt?.toIso8601String(),
    };
  }
}

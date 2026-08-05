import '../../domain/entities/repository.dart';

class GithubRepoModel extends GithubRepo {
  const GithubRepoModel({
    required super.id,
    required super.name,
    required super.fullName,
    required super.owner,
    required super.ownerAvatar,
    super.description,
    required super.isPrivate,
    required super.defaultBranch,
    required super.stargazersCount,
    required super.openIssuesCount,
    super.language,
    required super.updatedAt,
  });

  factory GithubRepoModel.fromJson(Map<String, dynamic> json) {
    final ownerMap = json['owner'] as Map<String, dynamic>? ?? {};
    return GithubRepoModel(
      id: json['id'] as int,
      name: json['name'] as String,
      fullName: (json['full_name'] as String?) ?? json['name'] as String,
      owner: (ownerMap['login'] as String?) ?? 'unknown',
      ownerAvatar: (ownerMap['avatar_url'] as String?) ?? '',
      description: json['description'] as String?,
      isPrivate: (json['private'] as bool?) ?? false,
      defaultBranch: (json['default_branch'] as String?) ?? 'main',
      stargazersCount: (json['stargazers_count'] as int?) ?? 0,
      openIssuesCount: (json['open_issues_count'] as int?) ?? 0,
      language: json['language'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'full_name': fullName,
      'owner': {
        'login': owner,
        'avatar_url': ownerAvatar,
      },
      'description': description,
      'private': isPrivate,
      'default_branch': defaultBranch,
      'stargazers_count': stargazersCount,
      'open_issues_count': openIssuesCount,
      'language': language,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

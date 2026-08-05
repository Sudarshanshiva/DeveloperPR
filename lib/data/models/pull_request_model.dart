import '../../domain/entities/pull_request.dart';

class PullRequestModel extends PullRequest {
  const PullRequestModel({
    required super.id,
    required super.number,
    required super.title,
    super.body,
    required super.state,
    required super.isDraft,
    required super.authorLogin,
    required super.authorAvatar,
    required super.createdAt,
    required super.updatedAt,
    required super.headBranch,
    required super.baseBranch,
    required super.htmlUrl,
    super.additions,
    super.deletions,
    super.changedFiles,
    super.ciState,
  });

  factory PullRequestModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>? ?? {};
    final headMap = json['head'] as Map<String, dynamic>? ?? {};
    final baseMap = json['base'] as Map<String, dynamic>? ?? {};

    return PullRequestModel(
      id: json['id'] as int,
      number: json['number'] as int,
      title: (json['title'] as String?) ?? 'Untitled PR',
      body: json['body'] as String?,
      state: (json['state'] as String?) ?? 'open',
      isDraft: (json['draft'] as bool?) ?? false,
      authorLogin: (userMap['login'] as String?) ?? 'ghost',
      authorAvatar: (userMap['avatar_url'] as String?) ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      headBranch: (headMap['ref'] as String?) ?? '',
      baseBranch: (baseMap['ref'] as String?) ?? '',
      htmlUrl: (json['html_url'] as String?) ?? '',
      additions: (json['additions'] as int?) ?? 0,
      deletions: (json['deletions'] as int?) ?? 0,
      changedFiles: (json['changed_files'] as int?) ?? 0,
      ciState: json['ci_state'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'title': title,
      'body': body,
      'state': state,
      'draft': isDraft,
      'user': {
        'login': authorLogin,
        'avatar_url': authorAvatar,
      },
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'head': {'ref': headBranch},
      'base': {'ref': baseBranch},
      'html_url': htmlUrl,
      'additions': additions,
      'deletions': deletions,
      'changed_files': changedFiles,
      'ci_state': ciState,
    };
  }
}

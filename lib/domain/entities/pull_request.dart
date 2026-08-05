import 'package:equatable/equatable.dart';

class PullRequest extends Equatable {
  final int id;
  final int number;
  final String title;
  final String? body;
  final String state;
  final bool isDraft;
  final String authorLogin;
  final String authorAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String headBranch;
  final String baseBranch;
  final String htmlUrl;
  final int additions;
  final int deletions;
  final int changedFiles;
  final String? ciState; // 'success', 'failure', 'pending', 'unknown'

  const PullRequest({
    required this.id,
    required this.number,
    required this.title,
    this.body,
    required this.state,
    required this.isDraft,
    required this.authorLogin,
    required this.authorAvatar,
    required this.createdAt,
    required this.updatedAt,
    required this.headBranch,
    required this.baseBranch,
    required this.htmlUrl,
    this.additions = 0,
    this.deletions = 0,
    this.changedFiles = 0,
    this.ciState,
  });

  @override
  List<Object?> get props => [
        id,
        number,
        title,
        body,
        state,
        isDraft,
        authorLogin,
        authorAvatar,
        createdAt,
        updatedAt,
        headBranch,
        baseBranch,
        htmlUrl,
        additions,
        deletions,
        changedFiles,
        ciState,
      ];
}

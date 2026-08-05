import 'package:equatable/equatable.dart';

class GithubRepo extends Equatable {
  final int id;
  final String name;
  final String fullName;
  final String owner;
  final String ownerAvatar;
  final String? description;
  final bool isPrivate;
  final String defaultBranch;
  final int stargazersCount;
  final int openIssuesCount;
  final String? language;
  final DateTime updatedAt;

  const GithubRepo({
    required this.id,
    required this.name,
    required this.fullName,
    required this.owner,
    required this.ownerAvatar,
    this.description,
    required this.isPrivate,
    required this.defaultBranch,
    required this.stargazersCount,
    required this.openIssuesCount,
    this.language,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        fullName,
        owner,
        ownerAvatar,
        description,
        isPrivate,
        defaultBranch,
        stargazersCount,
        openIssuesCount,
        language,
        updatedAt,
      ];
}

import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../entities/file_change.dart';
import '../entities/pr_analysis.dart';
import '../repositories/ai_analysis_repository.dart';

class AnalyzePullRequestParams {
  final String owner;
  final String repo;
  final int prNumber;
  final List<FileChange> files;
  final String prTitle;
  final String? prDescription;
  final bool forceRefresh;

  const AnalyzePullRequestParams({
    required this.owner,
    required this.repo,
    required this.prNumber,
    required this.files,
    required this.prTitle,
    this.prDescription,
    this.forceRefresh = false,
  });
}

class AnalyzePullRequestUseCase {
  final AiAnalysisRepository repository;

  AnalyzePullRequestUseCase(this.repository);

  Future<Either<Failure, PRAnalysisResult>> call(AnalyzePullRequestParams params) {
    return repository.analyzePullRequest(
      owner: params.owner,
      repo: params.repo,
      prNumber: params.prNumber,
      files: params.files,
      prTitle: params.prTitle,
      prDescription: params.prDescription,
      forceRefresh: params.forceRefresh,
    );
  }
}

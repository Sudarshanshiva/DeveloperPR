import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../entities/file_change.dart';
import '../entities/pull_request.dart';
import '../entities/repository.dart';
import '../entities/review.dart';
import '../entities/user.dart';

abstract class GithubRepository {
  Future<Either<Failure, User>> validateToken(String token);
  Future<Either<Failure, void>> saveToken(String token);
  Future<Either<Failure, String?>> getSavedToken();
  Future<Either<Failure, void>> logout();

  Future<Either<Failure, List<GithubRepo>>> getRepositories({
    String? username,
    int page = 1,
    int perPage = 30,
    String? query,
    bool forceRefresh = false,
  });

  Future<Either<Failure, List<PullRequest>>> getPullRequests({
    required String owner,
    required String repo,
    String state = 'open',
    int page = 1,
    int perPage = 30,
    bool forceRefresh = false,
  });

  Future<Either<Failure, PullRequest>> getPullRequestDetails({
    required String owner,
    required String repo,
    required int number,
    bool forceRefresh = false,
  });

  Future<Either<Failure, List<FileChange>>> getPRFiles({
    required String owner,
    required String repo,
    required int number,
  });

  Future<Either<Failure, List<Review>>> getPRReviews({
    required String owner,
    required String repo,
    required int number,
  });
}

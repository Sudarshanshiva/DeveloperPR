import 'package:fpdart/fpdart.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failure.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/file_change.dart';
import '../../domain/entities/pull_request.dart';
import '../../domain/entities/repository.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/github_repository.dart';
import '../datasources/github_local_datasource.dart';
import '../datasources/github_remote_datasource.dart';

class GithubRepositoryImpl implements GithubRepository {
  final GithubRemoteDataSource remoteDataSource;
  final GithubLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  GithubRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // Validate by looking up user by username
  @override
  Future<Either<Failure, User>> validateToken(String usernameOrToken) async {
    try {
      final userModel = await remoteDataSource.getUserByUsername(usernameOrToken);
      return Right(userModel);
    } on NetworkException {
      return Left(NetworkFailure());
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message, resetTimestamp: e.resetTimestamp));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveToken(String token) async {
    return const Right(null); // No-op — no token to save
  }

  @override
  Future<Either<Failure, String?>> getSavedToken() async {
    return const Right(null); // No saved token
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return const Right(null); // Just clears auth state
  }

  @override
  Future<Either<Failure, List<GithubRepo>>> getRepositories({
    String? username,
    int page = 1,
    int perPage = 30,
    String? query,
    bool forceRefresh = false,
  }) async {
    if (username == null || username.isEmpty) {
      return const Left(ServerFailure('Username is required'));
    }
    final isOnline = await networkInfo.isConnected;

    if (isOnline && (forceRefresh || query == null || query.isEmpty)) {
      try {
        final remoteRepos = await remoteDataSource.getUserRepositories(
          username: username,
          page: page,
          perPage: perPage,
        );
        if (page == 1 && (query == null || query.isEmpty)) {
          await localDataSource.cacheRepositories(remoteRepos);
        }
        return Right(remoteRepos);
      } on RateLimitException catch (e) {
        return Left(RateLimitFailure(e.message, resetTimestamp: e.resetTimestamp));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, statusCode: e.statusCode));
      } catch (_) {
        // Fallback to cache if available
      }
    }

    final cached = localDataSource.getCachedRepositories();
    if (cached != null && cached.isNotEmpty) {
      if (query != null && query.isNotEmpty) {
        final filtered = cached
            .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
        return Right(filtered);
      }
      return Right(cached);
    }

    if (!isOnline) {
      return Left(NetworkFailure());
    }

    return const Left(CacheFailure('No cached repository data available offline.'));
  }

  @override
  Future<Either<Failure, List<PullRequest>>> getPullRequests({
    required String owner,
    required String repo,
    String state = 'open',
    int page = 1,
    int perPage = 30,
    bool forceRefresh = false,
  }) async {
    final repoKey = '${owner}_${repo}_$state';
    final isOnline = await networkInfo.isConnected;

    if (isOnline) {
      try {
        final remotePRs = await remoteDataSource.getPullRequests(
          owner: owner,
          repo: repo,
          state: state,
          page: page,
          perPage: perPage,
        );
        if (page == 1) {
          await localDataSource.cachePullRequests(repoKey, remotePRs);
        }
        return Right(remotePRs);
      } on RateLimitException catch (e) {
        return Left(RateLimitFailure(e.message, resetTimestamp: e.resetTimestamp));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, statusCode: e.statusCode));
      } catch (_) {
        // Fallback to cache
      }
    }

    final cached = localDataSource.getCachedPullRequests(repoKey);
    if (cached != null) {
      return Right(cached);
    }

    if (!isOnline) {
      return Left(NetworkFailure());
    }

    return const Left(CacheFailure('No cached pull request data available.'));
  }

  @override
  Future<Either<Failure, PullRequest>> getPullRequestDetails({
    required String owner,
    required String repo,
    required int number,
    bool forceRefresh = false,
  }) async {
    final prKey = '${owner}_${repo}_$number';
    final isOnline = await networkInfo.isConnected;

    if (isOnline) {
      try {
        final remoteDetails = await remoteDataSource.getPullRequestDetails(
          owner: owner,
          repo: repo,
          number: number,
        );
        await localDataSource.cachePRDetails(prKey, remoteDetails);
        return Right(remoteDetails);
      } on RateLimitException catch (e) {
        return Left(RateLimitFailure(e.message, resetTimestamp: e.resetTimestamp));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, statusCode: e.statusCode));
      } catch (_) {
        // Fallback to cache
      }
    }

    final cached = localDataSource.getCachedPRDetails(prKey);
    if (cached != null) {
      return Right(cached);
    }

    if (!isOnline) {
      return Left(NetworkFailure());
    }

    return const Left(CacheFailure('No cached PR details available.'));
  }

  @override
  Future<Either<Failure, List<FileChange>>> getPRFiles({
    required String owner,
    required String repo,
    required int number,
  }) async {
    try {
      final files = await remoteDataSource.getPRFiles(
        owner: owner,
        repo: repo,
        number: number,
      );
      return Right(files);
    } on NetworkException {
      return Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Review>>> getPRReviews({
    required String owner,
    required String repo,
    required int number,
  }) async {
    try {
      final reviews = await remoteDataSource.getPRReviews(
        owner: owner,
        repo: repo,
        number: number,
      );
      return Right(reviews);
    } on NetworkException {
      return Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

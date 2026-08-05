import 'package:dio/dio.dart';
import '../../core/error/exceptions.dart';
import '../models/file_change_model.dart';
import '../models/pull_request_model.dart';
import '../models/repository_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

abstract class GithubRemoteDataSource {
  Future<UserModel> validateToken(String token);
  Future<List<GithubRepoModel>> getRepositories({int page = 1, int perPage = 30, String? query});
  Future<List<PullRequestModel>> getPullRequests({
    required String owner,
    required String repo,
    String state = 'open',
    int page = 1,
    int perPage = 30,
  });
  Future<PullRequestModel> getPullRequestDetails({
    required String owner,
    required String repo,
    required int number,
  });
  Future<List<FileChangeModel>> getPRFiles({
    required String owner,
    required String repo,
    required int number,
  });
  Future<List<ReviewModel>> getPRReviews({
    required String owner,
    required String repo,
    required int number,
  });
}

class GithubRemoteDataSourceImpl implements GithubRemoteDataSource {
  final Dio dio;

  GithubRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> validateToken(String token) async {
    try {
      final response = await dio.get(
        '/user',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to validate token', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  @override
  Future<List<GithubRepoModel>> getRepositories({
    int page = 1,
    int perPage = 30,
    String? query,
  }) async {
    try {
      Response response;
      if (query != null && query.isNotEmpty) {
        response = await dio.get(
          '/search/repositories',
          queryParameters: {
            'q': '$query in:name',
            'page': page,
            'per_page': perPage,
            'sort': 'updated',
          },
        );
        final items = (response.data['items'] as List?) ?? [];
        return items.map((e) => GithubRepoModel.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        response = await dio.get(
          '/user/repos',
          queryParameters: {
            'page': page,
            'per_page': perPage,
            'sort': 'updated',
            'affiliation': 'owner,collaborator,organization_member',
          },
        );
        final items = (response.data as List?) ?? [];
        return items.map((e) => GithubRepoModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  @override
  Future<List<PullRequestModel>> getPullRequests({
    required String owner,
    required String repo,
    String state = 'open',
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final response = await dio.get(
        '/repos/$owner/$repo/pulls',
        queryParameters: {
          'state': state,
          'page': page,
          'per_page': perPage,
          'sort': 'updated',
          'direction': 'desc',
        },
      );
      final items = (response.data as List?) ?? [];
      return items.map((e) => PullRequestModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  @override
  Future<PullRequestModel> getPullRequestDetails({
    required String owner,
    required String repo,
    required int number,
  }) async {
    try {
      final prResponse = await dio.get('/repos/$owner/$repo/pulls/$number');
      final prModel = PullRequestModel.fromJson(prResponse.data as Map<String, dynamic>);

      // Optionally fetch combined CI commit status
      String? ciState;
      try {
        final headSha = prResponse.data['head']?['sha'] as String?;
        if (headSha != null) {
          final statusResponse = await dio.get('/repos/$owner/$repo/commits/$headSha/status');
          ciState = statusResponse.data['state'] as String?;
        }
      } catch (_) {
        ciState = 'unknown';
      }

      return PullRequestModel(
        id: prModel.id,
        number: prModel.number,
        title: prModel.title,
        body: prModel.body,
        state: prModel.state,
        isDraft: prModel.isDraft,
        authorLogin: prModel.authorLogin,
        authorAvatar: prModel.authorAvatar,
        createdAt: prModel.createdAt,
        updatedAt: prModel.updatedAt,
        headBranch: prModel.headBranch,
        baseBranch: prModel.baseBranch,
        htmlUrl: prModel.htmlUrl,
        additions: prModel.additions,
        deletions: prModel.deletions,
        changedFiles: prModel.changedFiles,
        ciState: ciState ?? 'unknown',
      );
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  @override
  Future<List<FileChangeModel>> getPRFiles({
    required String owner,
    required String repo,
    required int number,
  }) async {
    try {
      final response = await dio.get('/repos/$owner/$repo/pulls/$number/files');
      final items = (response.data as List?) ?? [];
      return items.map((e) => FileChangeModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  @override
  Future<List<ReviewModel>> getPRReviews({
    required String owner,
    required String repo,
    required int number,
  }) async {
    try {
      final response = await dio.get('/repos/$owner/$repo/pulls/$number/reviews');
      final items = (response.data as List?) ?? [];
      return items.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  Never _handleDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      throw AuthException('Invalid or expired Personal Access Token');
    }
    if (e.response?.statusCode == 403 && e.response?.headers.value('x-ratelimit-remaining') == '0') {
      final resetStr = e.response?.headers.value('x-ratelimit-reset');
      final resetTs = int.tryParse(resetStr ?? '0') ?? 0;
      throw RateLimitException('GitHub API rate limit exceeded.', resetTimestamp: resetTs);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw NetworkException();
    }

    throw ServerException(
      e.response?.data?['message']?.toString() ?? e.message ?? 'Server error occurred',
      statusCode: e.response?.statusCode,
    );
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/cache/hive_cache_manager.dart';
import '../models/pull_request_model.dart';
import '../models/repository_model.dart';

abstract class GithubLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();

  Future<void> cacheRepositories(List<GithubRepoModel> repos);
  List<GithubRepoModel>? getCachedRepositories();

  Future<void> cachePullRequests(String repoKey, List<PullRequestModel> prs);
  List<PullRequestModel>? getCachedPullRequests(String repoKey);

  Future<void> cachePRDetails(String prKey, PullRequestModel pr);
  PullRequestModel? getCachedPRDetails(String prKey);
}

class GithubLocalDataSourceImpl implements GithubLocalDataSource {
  final FlutterSecureStorage secureStorage;
  final HiveCacheManager cacheManager;

  static const String tokenKey = 'GITHUB_PAT_TOKEN';

  GithubLocalDataSourceImpl({
    required this.secureStorage,
    required this.cacheManager,
  });

  @override
  Future<void> saveToken(String token) async {
    await secureStorage.write(key: tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await secureStorage.read(key: tokenKey);
  }

  @override
  Future<void> deleteToken() async {
    await secureStorage.delete(key: tokenKey);
    await cacheManager.clearAllCache();
  }

  @override
  Future<void> cacheRepositories(List<GithubRepoModel> repos) async {
    final jsonList = repos.map((e) => e.toJson()).toList();
    await cacheManager.cacheRepos(jsonList);
  }

  @override
  List<GithubRepoModel>? getCachedRepositories() {
    final cached = cacheManager.getCachedRepos();
    if (cached != null) {
      return cached.map((e) => GithubRepoModel.fromJson(e)).toList();
    }
    return null;
  }

  @override
  Future<void> cachePullRequests(String repoKey, List<PullRequestModel> prs) async {
    final jsonList = prs.map((e) => e.toJson()).toList();
    await cacheManager.cachePullRequests(repoKey, jsonList);
  }

  @override
  List<PullRequestModel>? getCachedPullRequests(String repoKey) {
    final cached = cacheManager.getCachedPullRequests(repoKey);
    if (cached != null) {
      return cached.map((e) => PullRequestModel.fromJson(e)).toList();
    }
    return null;
  }

  @override
  Future<void> cachePRDetails(String prKey, PullRequestModel pr) async {
    await cacheManager.cachePRDetails(prKey, pr.toJson());
  }

  @override
  PullRequestModel? getCachedPRDetails(String prKey) {
    final cached = cacheManager.getCachedPRDetails(prKey);
    if (cached != null) {
      return PullRequestModel.fromJson(cached);
    }
    return null;
  }
}

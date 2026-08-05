import 'package:hive_flutter/hive_flutter.dart';

class HiveCacheManager {
  static const String reposBoxName = 'github_repos_cache';
  static const String prsBoxName = 'github_prs_cache';
  static const String prDetailsBoxName = 'github_pr_details_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(reposBoxName);
    await Hive.openBox(prsBoxName);
    await Hive.openBox(prDetailsBoxName);
  }

  Box get reposBox => Hive.box(reposBoxName);
  Box get prsBox => Hive.box(prsBoxName);
  Box get prDetailsBox => Hive.box(prDetailsBoxName);

  Future<void> cacheRepos(List<Map<String, dynamic>> jsonList) async {
    await reposBox.put('user_repos', jsonList);
    await reposBox.put('repos_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  List<Map<String, dynamic>>? getCachedRepos() {
    final raw = reposBox.get('user_repos');
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  Future<void> cachePullRequests(String repoKey, List<Map<String, dynamic>> jsonList) async {
    await prsBox.put(repoKey, jsonList);
  }

  List<Map<String, dynamic>>? getCachedPullRequests(String repoKey) {
    final raw = prsBox.get(repoKey);
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  Future<void> cachePRDetails(String prKey, Map<String, dynamic> jsonMap) async {
    await prDetailsBox.put(prKey, jsonMap);
  }

  Map<String, dynamic>? getCachedPRDetails(String prKey) {
    final raw = prDetailsBox.get(prKey);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  Future<void> clearAllCache() async {
    await reposBox.clear();
    await prsBox.clear();
    await prDetailsBox.clear();
  }
}

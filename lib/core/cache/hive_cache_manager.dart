import 'package:hive_flutter/hive_flutter.dart';

class HiveCacheManager {
  static const String reposBoxName = 'github_repos_cache';
  static const String prsBoxName = 'github_prs_cache';
  static const String prDetailsBoxName = 'github_pr_details_cache';
  static const String prNotesBoxName = 'github_pr_notes_cache';
  static const String aiAnalysisBoxName = 'ai_analysis_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(reposBoxName);
    await Hive.openBox(prsBoxName);
    await Hive.openBox(prDetailsBoxName);
    await Hive.openBox(prNotesBoxName);
    await Hive.openBox(aiAnalysisBoxName);
  }

  Box get reposBox => Hive.box(reposBoxName);
  Box get prsBox => Hive.box(prsBoxName);
  Box get prDetailsBox => Hive.box(prDetailsBoxName);
  Box get prNotesBox => Hive.box(prNotesBoxName);
  Box get aiAnalysisBox => Hive.box(aiAnalysisBoxName);

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

  // Custom PR Notes/Descriptions
  Future<void> savePRNote(String prKey, String note) async {
    await prNotesBox.put(prKey, note);
  }

  String? getPRNote(String prKey) {
    return prNotesBox.get(prKey) as String?;
  }

  // AI PR Analysis Cache
  Future<void> cacheAiAnalysis(String aiKey, Map<String, dynamic> jsonMap) async {
    await aiAnalysisBox.put(aiKey, jsonMap);
  }

  Map<String, dynamic>? getCachedAiAnalysis(String aiKey) {
    final raw = aiAnalysisBox.get(aiKey);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  // Freemium Quota & Pro Membership Tracking
  String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  int getDailyFreeAiUsage() {
    final storedDate = aiAnalysisBox.get('free_quota_date') as String?;
    final today = _todayDateKey();
    if (storedDate != today) {
      // Reset for new day
      aiAnalysisBox.put('free_quota_date', today);
      aiAnalysisBox.put('free_quota_count', 0);
      return 0;
    }
    return (aiAnalysisBox.get('free_quota_count') as int?) ?? 0;
  }

  Future<void> incrementDailyFreeAiUsage() async {
    final current = getDailyFreeAiUsage();
    await aiAnalysisBox.put('free_quota_count', current + 1);
  }

  bool isProStatus() {
    return (aiAnalysisBox.get('is_pro_member') as bool?) ?? false;
  }

  Future<void> setProStatus(bool isPro) async {
    await aiAnalysisBox.put('is_pro_member', isPro);
  }

  Future<void> clearAllCache() async {
    await reposBox.clear();
    await prsBox.clear();
    await prDetailsBox.clear();
    await prNotesBox.clear();
    await aiAnalysisBox.clear();
  }
}

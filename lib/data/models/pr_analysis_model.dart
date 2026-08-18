import '../../domain/entities/pr_analysis.dart';

class PRPotentialIssueModel extends PRPotentialIssue {
  const PRPotentialIssueModel({
    required super.file,
    super.line,
    required super.issue,
    required super.severity,
  });

  factory PRPotentialIssueModel.fromJson(Map<String, dynamic> json) {
    return PRPotentialIssueModel(
      file: json['file']?.toString() ?? 'Unknown File',
      line: json['line'] is int ? json['line'] as int : int.tryParse(json['line']?.toString() ?? ''),
      issue: json['issue']?.toString() ?? 'Issue detected',
      severity: (json['severity']?.toString() ?? 'low').toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file': file,
      'line': line,
      'issue': issue,
      'severity': severity,
    };
  }
}

class PRAnalysisResultModel extends PRAnalysisResult {
  const PRAnalysisResultModel({
    required super.summary,
    required super.riskLevel,
    required super.potentialIssues,
    required super.suggestions,
    required super.testCoverage,
    required super.isTruncated,
    required super.analyzedFileCount,
    required super.analyzedAt,
  });

  factory PRAnalysisResultModel.fromJson(
    Map<String, dynamic> json, {
    required bool isTruncated,
    required int analyzedFileCount,
    DateTime? analyzedAt,
  }) {
    final rawIssues = (json['potentialIssues'] as List?) ?? [];
    final issues = rawIssues
        .whereType<Map>()
        .map((e) => PRPotentialIssueModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawSuggestions = (json['suggestions'] as List?) ?? [];
    final suggestions = rawSuggestions.map((e) => e.toString()).toList();

    return PRAnalysisResultModel(
      summary: json['summary']?.toString() ?? 'No summary available.',
      riskLevel: (json['riskLevel']?.toString() ?? 'low').toLowerCase(),
      potentialIssues: issues,
      suggestions: suggestions,
      testCoverage: json['testCoverage']?.toString() ?? 'No test coverage comment available.',
      isTruncated: isTruncated,
      analyzedFileCount: analyzedFileCount,
      analyzedAt: analyzedAt ?? DateTime.now(),
    );
  }

  factory PRAnalysisResultModel.fromCacheJson(Map<String, dynamic> json) {
    final rawIssues = (json['potentialIssues'] as List?) ?? [];
    final issues = rawIssues
        .whereType<Map>()
        .map((e) => PRPotentialIssueModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawSuggestions = (json['suggestions'] as List?) ?? [];
    final suggestions = rawSuggestions.map((e) => e.toString()).toList();

    return PRAnalysisResultModel(
      summary: json['summary']?.toString() ?? '',
      riskLevel: json['riskLevel']?.toString() ?? 'low',
      potentialIssues: issues,
      suggestions: suggestions,
      testCoverage: json['testCoverage']?.toString() ?? '',
      isTruncated: json['isTruncated'] == true,
      analyzedFileCount: (json['analyzedFileCount'] as int?) ?? 0,
      analyzedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['analyzedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'summary': summary,
      'riskLevel': riskLevel,
      'potentialIssues': potentialIssues
          .map((e) => (e as PRPotentialIssueModel).toJson())
          .toList(),
      'suggestions': suggestions,
      'testCoverage': testCoverage,
      'isTruncated': isTruncated,
      'analyzedFileCount': analyzedFileCount,
      'analyzedAt': analyzedAt.millisecondsSinceEpoch,
    };
  }
}

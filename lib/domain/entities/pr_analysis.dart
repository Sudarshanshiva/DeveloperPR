import 'package:equatable/equatable.dart';

class PRPotentialIssue extends Equatable {
  final String file;
  final int? line;
  final String issue;
  final String severity; // 'high' | 'medium' | 'low'

  const PRPotentialIssue({
    required this.file,
    this.line,
    required this.issue,
    required this.severity,
  });

  @override
  List<Object?> get props => [file, line, issue, severity];
}

class PRAnalysisResult extends Equatable {
  final String summary;
  final String riskLevel; // 'low' | 'medium' | 'high'
  final List<PRPotentialIssue> potentialIssues;
  final List<String> suggestions;
  final String testCoverage;
  final bool isTruncated;
  final int analyzedFileCount;
  final DateTime analyzedAt;

  const PRAnalysisResult({
    required this.summary,
    required this.riskLevel,
    required this.potentialIssues,
    required this.suggestions,
    required this.testCoverage,
    required this.isTruncated,
    required this.analyzedFileCount,
    required this.analyzedAt,
  });

  @override
  List<Object?> get props => [
        summary,
        riskLevel,
        potentialIssues,
        suggestions,
        testCoverage,
        isTruncated,
        analyzedFileCount,
        analyzedAt,
      ];
}

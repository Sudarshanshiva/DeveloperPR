import 'package:equatable/equatable.dart';
import '../../../domain/entities/pr_analysis.dart';
import '../../../domain/entities/user_quota.dart';

abstract class AiAnalysisState extends Equatable {
  const AiAnalysisState();
  @override
  List<Object?> get props => [];
}

class AiAnalysisInitial extends AiAnalysisState {}

class AiAnalysisNoKeyConfigured extends AiAnalysisState {
  final String provider;
  final UserQuota? quota;

  const AiAnalysisNoKeyConfigured({this.provider = 'gemini', this.quota});

  @override
  List<Object?> get props => [provider, quota];
}

class AiAnalysisReadyToAnalyze extends AiAnalysisState {
  final String provider;
  final UserQuota quota;
  final bool hasCachedResult;
  final PRAnalysisResult? cachedResult;

  const AiAnalysisReadyToAnalyze({
    required this.provider,
    required this.quota,
    this.hasCachedResult = false,
    this.cachedResult,
  });

  @override
  List<Object?> get props => [provider, quota, hasCachedResult, cachedResult];
}

class AiAnalysisLoading extends AiAnalysisState {
  final String message;
  const AiAnalysisLoading({this.message = 'Analyzing PR code diffs with AI...'});

  @override
  List<Object?> get props => [message];
}

class AiAnalysisLoaded extends AiAnalysisState {
  final PRAnalysisResult result;
  final String provider;
  final UserQuota quota;

  const AiAnalysisLoaded({
    required this.result,
    required this.provider,
    required this.quota,
  });

  @override
  List<Object?> get props => [result, provider, quota];
}

class AiAnalysisQuotaExceededState extends AiAnalysisState {
  final String message;
  final UserQuota quota;

  const AiAnalysisQuotaExceededState({
    required this.message,
    required this.quota,
  });

  @override
  List<Object?> get props => [message, quota];
}

class AiAnalysisError extends AiAnalysisState {
  final String message;
  final bool isAuthError;
  final bool isQuotaError;

  const AiAnalysisError({
    required this.message,
    this.isAuthError = false,
    this.isQuotaError = false,
  });

  @override
  List<Object?> get props => [message, isAuthError, isQuotaError];
}

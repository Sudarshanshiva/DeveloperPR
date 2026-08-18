import 'package:equatable/equatable.dart';
import '../../../domain/entities/pr_analysis.dart';

abstract class AiAnalysisState extends Equatable {
  const AiAnalysisState();
  @override
  List<Object?> get props => [];
}

class AiAnalysisInitial extends AiAnalysisState {}

class AiAnalysisNoKeyConfigured extends AiAnalysisState {
  final String provider;
  const AiAnalysisNoKeyConfigured({this.provider = 'claude'});

  @override
  List<Object?> get props => [provider];
}

class AiAnalysisReadyToAnalyze extends AiAnalysisState {
  final String provider;
  final bool hasCachedResult;
  final PRAnalysisResult? cachedResult;

  const AiAnalysisReadyToAnalyze({
    required this.provider,
    this.hasCachedResult = false,
    this.cachedResult,
  });

  @override
  List<Object?> get props => [provider, hasCachedResult, cachedResult];
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

  const AiAnalysisLoaded({
    required this.result,
    required this.provider,
  });

  @override
  List<Object?> get props => [result, provider];
}

class AiAnalysisError extends AiAnalysisState {
  final String message;
  final bool isAuthError;

  const AiAnalysisError({required this.message, this.isAuthError = false});

  @override
  List<Object?> get props => [message, isAuthError];
}

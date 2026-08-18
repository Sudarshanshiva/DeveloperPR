import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure.dart';
import '../../../domain/repositories/ai_analysis_repository.dart';
import '../../../domain/usecases/analyze_pull_request_usecase.dart';
import 'ai_analysis_event.dart';
import 'ai_analysis_state.dart';

class AiAnalysisBloc extends Bloc<AiAnalysisEvent, AiAnalysisState> {
  final AiAnalysisRepository repository;
  final AnalyzePullRequestUseCase analyzePullRequestUseCase;

  AiAnalysisBloc({
    required this.repository,
    required this.analyzePullRequestUseCase,
  }) : super(AiAnalysisInitial()) {
    on<CheckAiApiKeyStatusEvent>(_onCheckApiKeyStatus);
    on<SaveAiApiKeyEvent>(_onSaveApiKey);
    on<DeleteAiApiKeyEvent>(_onDeleteApiKey);
    on<RunAiAnalysisEvent>(_onRunAiAnalysis);
  }

  Future<void> _onCheckApiKeyStatus(
    CheckAiApiKeyStatusEvent event,
    Emitter<AiAnalysisState> emit,
  ) async {
    final keyResult = await repository.getApiKey();
    final providerResult = await repository.getApiProvider();
    final provider = providerResult.getOrElse((_) => 'claude');

    keyResult.fold(
      (failure) => emit(AiAnalysisNoKeyConfigured(provider: provider)),
      (key) {
        if (key != null && key.trim().isNotEmpty) {
          emit(AiAnalysisReadyToAnalyze(provider: provider));
        } else {
          emit(AiAnalysisNoKeyConfigured(provider: provider));
        }
      },
    );
  }

  Future<void> _onSaveApiKey(
    SaveAiApiKeyEvent event,
    Emitter<AiAnalysisState> emit,
  ) async {
    final result = await repository.saveApiKey(event.apiKey, provider: event.provider);
    result.fold(
      (failure) => emit(AiAnalysisError(message: failure.message)),
      (_) => emit(AiAnalysisReadyToAnalyze(provider: event.provider)),
    );
  }

  Future<void> _onDeleteApiKey(
    DeleteAiApiKeyEvent event,
    Emitter<AiAnalysisState> emit,
  ) async {
    final providerResult = await repository.getApiProvider();
    final provider = providerResult.getOrElse((_) => 'claude');
    await repository.deleteApiKey();
    emit(AiAnalysisNoKeyConfigured(provider: provider));
  }

  Future<void> _onRunAiAnalysis(
    RunAiAnalysisEvent event,
    Emitter<AiAnalysisState> emit,
  ) async {
    final providerResult = await repository.getApiProvider();
    final provider = providerResult.getOrElse((_) => 'claude');

    emit(const AiAnalysisLoading(message: 'Analyzing PR code diffs & assessing risks...'));

    final result = await analyzePullRequestUseCase(
      AnalyzePullRequestParams(
        owner: event.owner,
        repo: event.repo,
        prNumber: event.prNumber,
        files: event.files,
        prTitle: event.prTitle,
        prDescription: event.prDescription,
        forceRefresh: event.forceRefresh,
      ),
    );

    result.fold(
      (failure) {
        if (failure is AuthFailure) {
          emit(AiAnalysisError(message: failure.message, isAuthError: true));
        } else {
          emit(AiAnalysisError(message: failure.message));
        }
      },
      (analysis) => emit(AiAnalysisLoaded(result: analysis, provider: provider)),
    );
  }
}

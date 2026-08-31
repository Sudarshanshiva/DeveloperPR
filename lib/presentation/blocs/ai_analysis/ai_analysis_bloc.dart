import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/error/failure.dart';
import '../../../domain/entities/user_quota.dart';
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
    on<CheckUserQuotaEvent>(_onCheckUserQuota);
    on<UnlockProSubscriptionEvent>(_onUnlockProSubscription);
    on<SaveAiApiKeyEvent>(_onSaveApiKey);
    on<DeleteAiApiKeyEvent>(_onDeleteApiKey);
    on<RunAiAnalysisEvent>(_onRunAiAnalysis);
  }

  Future<void> _onCheckApiKeyStatus(
    CheckAiApiKeyStatusEvent event,
    Emitter<AiAnalysisState> emit,
  ) async {
    final providerResult = await repository.getApiProvider();
    final provider = providerResult.getOrElse((_) => 'gemini');
    final quotaResult = await repository.getUserQuota();
    
    final quota = quotaResult.getOrElse(
      (_) => const UserQuota(usedToday: 0, maxDailyFree: 3, isProMember: false, hasCustomKey: false),
    );

    // If quota is exhausted and user has no custom key / Pro status
    if (!quota.canAnalyze) {
      emit(AiAnalysisQuotaExceededState(
        message: 'Daily free AI PR review limit reached (3/3 used today).',
        quota: quota,
      ));
    } else {
      emit(AiAnalysisReadyToAnalyze(provider: provider, quota: quota));
    }
  }

  Future<void> _onCheckUserQuota(
    CheckUserQuotaEvent event,
    Emitter<AiAnalysisState> emit,
  ) async {
    final providerResult = await repository.getApiProvider();
    final provider = providerResult.getOrElse((_) => 'gemini');
    final quotaResult = await repository.getUserQuota();

    final quota = quotaResult.getOrElse(
      (_) => const UserQuota(usedToday: 0, maxDailyFree: 3, isProMember: false, hasCustomKey: false),
    );

    if (!quota.canAnalyze) {
      emit(AiAnalysisQuotaExceededState(
        message: 'Daily free AI PR review limit reached (3/3 used today).',
        quota: quota,
      ));
    } else {
      emit(AiAnalysisReadyToAnalyze(provider: provider, quota: quota));
    }
  }

  Future<void> _onUnlockProSubscription(
    UnlockProSubscriptionEvent event,
    Emitter<AiAnalysisState> emit,
  ) async {
    await repository.unlockProSubscription();
    add(CheckAiApiKeyStatusEvent());
  }

  Future<void> _onSaveApiKey(
    SaveAiApiKeyEvent event,
    Emitter<AiAnalysisState> emit,
  ) async {
    final result = await repository.saveApiKey(event.apiKey, provider: event.provider);
    result.fold(
      (failure) => emit(AiAnalysisError(message: failure.message)),
      (_) => add(CheckAiApiKeyStatusEvent()),
    );
  }

  Future<void> _onDeleteApiKey(
    DeleteAiApiKeyEvent event,
    Emitter<AiAnalysisState> emit,
  ) async {
    await repository.deleteApiKey();
    add(CheckAiApiKeyStatusEvent());
  }

  Future<void> _onRunAiAnalysis(
    RunAiAnalysisEvent event,
    Emitter<AiAnalysisState> emit,
  ) async {
    final providerResult = await repository.getApiProvider();
    final provider = providerResult.getOrElse((_) => 'gemini');
    final quotaResult = await repository.getUserQuota();
    final quota = quotaResult.getOrElse(
      (_) => const UserQuota(usedToday: 0, maxDailyFree: 3, isProMember: false, hasCustomKey: false),
    );

    if (!quota.canAnalyze) {
      emit(AiAnalysisQuotaExceededState(
        message: 'Daily free AI PR review limit reached (3/3 used today).',
        quota: quota,
      ));
      return;
    }

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

    // Refresh quota after analysis
    final updatedQuotaResult = await repository.getUserQuota();
    final updatedQuota = updatedQuotaResult.getOrElse((_) => quota);

    result.fold(
      (failure) {
        if (failure is QuotaExceededFailure) {
          emit(AiAnalysisQuotaExceededState(
            message: failure.message,
            quota: updatedQuota,
          ));
        } else if (failure is AuthFailure) {
          emit(AiAnalysisError(message: failure.message, isAuthError: true));
        } else {
          emit(AiAnalysisError(message: failure.message));
        }
      },
      (analysis) => emit(AiAnalysisLoaded(result: analysis, provider: provider, quota: updatedQuota)),
    );
  }
}

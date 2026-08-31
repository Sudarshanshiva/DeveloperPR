import 'package:equatable/equatable.dart';
import '../../../domain/entities/file_change.dart';

abstract class AiAnalysisEvent extends Equatable {
  const AiAnalysisEvent();
  @override
  List<Object?> get props => [];
}

class CheckAiApiKeyStatusEvent extends AiAnalysisEvent {}

class CheckUserQuotaEvent extends AiAnalysisEvent {}

class UnlockProSubscriptionEvent extends AiAnalysisEvent {}

class SaveAiApiKeyEvent extends AiAnalysisEvent {
  final String apiKey;
  final String provider;
  const SaveAiApiKeyEvent({required this.apiKey, this.provider = 'gemini'});

  @override
  List<Object?> get props => [apiKey, provider];
}

class DeleteAiApiKeyEvent extends AiAnalysisEvent {}

class RunAiAnalysisEvent extends AiAnalysisEvent {
  final String owner;
  final String repo;
  final int prNumber;
  final List<FileChange> files;
  final String prTitle;
  final String? prDescription;
  final bool forceRefresh;

  const RunAiAnalysisEvent({
    required this.owner,
    required this.repo,
    required this.prNumber,
    required this.files,
    required this.prTitle,
    this.prDescription,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [owner, repo, prNumber, files, prTitle, prDescription, forceRefresh];
}

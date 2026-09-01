import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../entities/file_change.dart';
import '../entities/pr_analysis.dart';
import '../entities/user_quota.dart';

abstract class AiAnalysisRepository {
  Future<Either<Failure, PRAnalysisResult>> analyzePullRequest({
    required String owner,
    required String repo,
    required int prNumber,
    required List<FileChange> files,
    required String prTitle,
    String? prDescription,
    bool forceRefresh = false,
  });

  Future<Either<Failure, void>> saveApiKey(String apiKey, {String provider = 'claude'});
  Future<Either<Failure, String?>> getApiKey();
  Future<Either<Failure, String>> getApiProvider();
  Future<Either<Failure, void>> deleteApiKey();

  Future<Either<Failure, UserQuota>> getUserQuota();
  Future<Either<Failure, void>> unlockProSubscription();
}


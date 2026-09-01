import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/cache/hive_cache_manager.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/file_change.dart';
import '../../domain/entities/pr_analysis.dart';
import '../../domain/entities/user_quota.dart';
import '../../domain/repositories/ai_analysis_repository.dart';
import '../datasources/ai_remote_datasource.dart';
import '../models/pr_analysis_model.dart';

class AiAnalysisRepositoryImpl implements AiAnalysisRepository {
  final AiRemoteDataSource remoteDataSource;
  final HiveCacheManager cacheManager;
  final FlutterSecureStorage secureStorage;

  static const String _apiKeyStorageKey = 'user_ai_api_key';
  static const String _apiProviderStorageKey = 'user_ai_api_provider';

  AiAnalysisRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheManager,
    required this.secureStorage,
  });

  @override
  Future<Either<Failure, UserQuota>> getUserQuota() async {
    try {
      final key = await secureStorage.read(key: _apiKeyStorageKey);
      final hasCustomKey = key != null && key.trim().isNotEmpty;
      final isPro = cacheManager.isProStatus();
      final usedToday = cacheManager.getDailyFreeAiUsage();

      return Right(
        UserQuota(
          usedToday: usedToday,
          maxDailyFree: 3,
          isProMember: isPro,
          hasCustomKey: hasCustomKey,
        ),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to get quota status: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unlockProSubscription() async {
    try {
      await cacheManager.setProStatus(true);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to unlock Pro subscription: $e'));
    }
  }

  @override
  Future<Either<Failure, PRAnalysisResult>> analyzePullRequest({
    required String owner,
    required String repo,
    required int prNumber,
    required List<FileChange> files,
    required String prTitle,
    String? prDescription,
    bool forceRefresh = false,
  }) async {
    try {
      final customKey = await secureStorage.read(key: _apiKeyStorageKey);
      final hasCustomKey = customKey != null && customKey.trim().isNotEmpty;
      final isPro = cacheManager.isProStatus();
      final usedToday = cacheManager.getDailyFreeAiUsage();

      // Check quota if not Pro and no custom key
      if (!isPro && !hasCustomKey && usedToday >= 3) {
        return const Left(QuotaExceededFailure(
          'Daily free AI PR review limit reached (3/3 used today).',
          remainingFreeCount: 0,
        ));
      }

      final provider = (await secureStorage.read(key: _apiProviderStorageKey)) ?? 'gemini';
      final cacheKey = '${owner}_${repo}_${prNumber}_${files.length}';

      if (!forceRefresh) {
        final cached = cacheManager.getCachedAiAnalysis(cacheKey);
        if (cached != null) {
          return Right(PRAnalysisResultModel.fromCacheJson(cached));
        }
      }

      // Key to use: custom key if present, otherwise fallback to datasource default or check auth
      final effectiveKey = hasCustomKey ? customKey.trim() : '';

      final result = await remoteDataSource.analyzePullRequest(
        apiKey: effectiveKey,
        provider: provider,
        prTitle: prTitle,
        prDescription: prDescription,
        files: files,
      );

      // Cache result and increment free usage if using free tier
      await cacheManager.cacheAiAnalysis(cacheKey, result.toCacheJson());
      if (!isPro && !hasCustomKey) {
        await cacheManager.incrementDailyFreeAiUsage();
      }

      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message, resetTimestamp: e.resetTimestamp));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveApiKey(String apiKey, {String provider = 'gemini'}) async {
    try {
      await secureStorage.write(key: _apiKeyStorageKey, value: apiKey.trim());
      await secureStorage.write(key: _apiProviderStorageKey, value: provider.toLowerCase());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save API key: $e'));
    }
  }

  @override
  Future<Either<Failure, String?>> getApiKey() async {
    try {
      final key = await secureStorage.read(key: _apiKeyStorageKey);
      return Right(key);
    } catch (e) {
      return Left(CacheFailure('Failed to read API key: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getApiProvider() async {
    try {
      final provider = await secureStorage.read(key: _apiProviderStorageKey);
      return Right(provider ?? 'gemini');
    } catch (_) {
      return const Right('gemini');
    }
  }

  @override
  Future<Either<Failure, void>> deleteApiKey() async {
    try {
      await secureStorage.delete(key: _apiKeyStorageKey);
      await secureStorage.delete(key: _apiProviderStorageKey);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to remove API key: $e'));
    }
  }
}

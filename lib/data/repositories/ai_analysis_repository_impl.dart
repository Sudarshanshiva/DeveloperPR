import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/cache/hive_cache_manager.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/file_change.dart';
import '../../domain/entities/pr_analysis.dart';
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
      final apiKey = await secureStorage.read(key: _apiKeyStorageKey);
      if (apiKey == null || apiKey.trim().isEmpty) {
        return const Left(AuthFailure('No AI API Key configured. Please add your Claude or OpenAI API key in settings.'));
      }

      final provider = (await secureStorage.read(key: _apiProviderStorageKey)) ?? 'claude';
      final cacheKey = '${owner}_${repo}_${prNumber}_${files.length}';

      if (!forceRefresh) {
        final cached = cacheManager.getCachedAiAnalysis(cacheKey);
        if (cached != null) {
          return Right(PRAnalysisResultModel.fromCacheJson(cached));
        }
      }

      final result = await remoteDataSource.analyzePullRequest(
        apiKey: apiKey.trim(),
        provider: provider,
        prTitle: prTitle,
        prDescription: prDescription,
        files: files,
      );

      await cacheManager.cacheAiAnalysis(cacheKey, result.toCacheJson());
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
  Future<Either<Failure, void>> saveApiKey(String apiKey, {String provider = 'claude'}) async {
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
      return Right(provider ?? 'claude');
    } catch (_) {
      return const Right('claude');
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

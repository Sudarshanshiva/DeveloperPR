import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dev_util/core/network/network_info.dart';
import 'package:dev_util/data/datasources/github_local_datasource.dart';
import 'package:dev_util/data/datasources/github_remote_datasource.dart';
import 'package:dev_util/data/models/repository_model.dart';
import 'package:dev_util/data/repositories/github_repository_impl.dart';

class MockGithubRemoteDataSource extends Mock implements GithubRemoteDataSource {}
class MockGithubLocalDataSource extends Mock implements GithubLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late GithubRepositoryImpl repository;
  late MockGithubRemoteDataSource mockRemoteDataSource;
  late MockGithubLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockGithubRemoteDataSource();
    mockLocalDataSource = MockGithubLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = GithubRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  final tRepoModelList = [
    GithubRepoModel(
      id: 1,
      name: 'flutter_dashboard',
      fullName: 'user/flutter_dashboard',
      owner: 'user',
      ownerAvatar: 'https://avatar.url',
      description: 'Clean Architecture dashboard',
      isPrivate: true,
      defaultBranch: 'main',
      stargazersCount: 100,
      openIssuesCount: 5,
      language: 'Dart',
      updatedAt: DateTime(2026, 2, 1),
    ),
  ];

  group('getRepositories', () {
    test('should return remote data and cache it when device is online', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getRepositories(page: 1, perPage: 30, query: null))
          .thenAnswer((_) async => tRepoModelList);
      when(() => mockLocalDataSource.cacheRepositories(tRepoModelList))
          .thenAnswer((_) async => {});

      // act
      final result = await repository.getRepositories(page: 1);

      // assert
      expect(result, Right(tRepoModelList));
      verify(() => mockRemoteDataSource.getRepositories(page: 1, perPage: 30, query: null)).called(1);
      verify(() => mockLocalDataSource.cacheRepositories(tRepoModelList)).called(1);
    });

    test('should return cached data when device is offline', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.getCachedRepositories()).thenReturn(tRepoModelList);

      // act
      final result = await repository.getRepositories(page: 1);

      // assert
      expect(result, Right(tRepoModelList));
      verifyZeroInteractions(mockRemoteDataSource);
      verify(() => mockLocalDataSource.getCachedRepositories()).called(1);
    });
  });
}

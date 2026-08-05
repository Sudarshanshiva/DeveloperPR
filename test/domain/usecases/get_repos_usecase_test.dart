import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dev_util/domain/entities/repository.dart';
import 'package:dev_util/domain/repositories/github_repository.dart';
import 'package:dev_util/domain/usecases/get_repos_usecase.dart';

class MockGithubRepository extends Mock implements GithubRepository {}

void main() {
  late GetReposUseCase usecase;
  late MockGithubRepository mockGithubRepository;

  setUp(() {
    mockGithubRepository = MockGithubRepository();
    usecase = GetReposUseCase(mockGithubRepository);
  });

  final tRepoList = [
    GithubRepo(
      id: 1,
      name: 'dev_util',
      fullName: 'user/dev_util',
      owner: 'user',
      ownerAvatar: 'https://avatar.url',
      description: 'Flutter PR Dashboard',
      isPrivate: false,
      defaultBranch: 'main',
      stargazersCount: 42,
      openIssuesCount: 3,
      language: 'Dart',
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  test('should fetch github repositories from the repository contract', () async {
    // arrange
    when(() => mockGithubRepository.getRepositories(
          page: 1,
          perPage: 30,
          query: null,
          forceRefresh: false,
        )).thenAnswer((_) async => Right(tRepoList));

    // act
    final result = await usecase(const GetReposParams(page: 1));

    // assert
    expect(result, Right(tRepoList));
    verify(() => mockGithubRepository.getRepositories(
          page: 1,
          perPage: 30,
          query: null,
          forceRefresh: false,
        )).called(1);
    verifyNoMoreInteractions(mockGithubRepository);
  });
}

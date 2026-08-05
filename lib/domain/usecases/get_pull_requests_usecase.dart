import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../../core/usecases/usecase.dart';
import '../entities/pull_request.dart';
import '../repositories/github_repository.dart';

class GetPRsParams extends Equatable {
  final String owner;
  final String repo;
  final String state;
  final int page;
  final int perPage;
  final bool forceRefresh;

  const GetPRsParams({
    required this.owner,
    required this.repo,
    this.state = 'open',
    this.page = 1,
    this.perPage = 30,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [owner, repo, state, page, perPage, forceRefresh];
}

class GetPullRequestsUseCase implements UseCase<List<PullRequest>, GetPRsParams> {
  final GithubRepository repository;

  GetPullRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PullRequest>>> call(GetPRsParams params) async {
    return await repository.getPullRequests(
      owner: params.owner,
      repo: params.repo,
      state: params.state,
      page: params.page,
      perPage: params.perPage,
      forceRefresh: params.forceRefresh,
    );
  }
}

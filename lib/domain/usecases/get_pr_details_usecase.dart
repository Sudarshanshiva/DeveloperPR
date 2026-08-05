import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../../core/usecases/usecase.dart';
import '../entities/pull_request.dart';
import '../repositories/github_repository.dart';

class GetPRDetailsParams extends Equatable {
  final String owner;
  final String repo;
  final int number;
  final bool forceRefresh;

  const GetPRDetailsParams({
    required this.owner,
    required this.repo,
    required this.number,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [owner, repo, number, forceRefresh];
}

class GetPRDetailsUseCase implements UseCase<PullRequest, GetPRDetailsParams> {
  final GithubRepository repository;

  GetPRDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, PullRequest>> call(GetPRDetailsParams params) async {
    return await repository.getPullRequestDetails(
      owner: params.owner,
      repo: params.repo,
      number: params.number,
      forceRefresh: params.forceRefresh,
    );
  }
}

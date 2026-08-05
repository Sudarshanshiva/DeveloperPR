import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../../core/usecases/usecase.dart';
import '../entities/repository.dart';
import '../repositories/github_repository.dart';

class GetReposParams extends Equatable {
  final int page;
  final int perPage;
  final String? query;
  final bool forceRefresh;

  const GetReposParams({
    this.page = 1,
    this.perPage = 30,
    this.query,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [page, perPage, query, forceRefresh];
}

class GetReposUseCase implements UseCase<List<GithubRepo>, GetReposParams> {
  final GithubRepository repository;

  GetReposUseCase(this.repository);

  @override
  Future<Either<Failure, List<GithubRepo>>> call(GetReposParams params) async {
    return await repository.getRepositories(
      page: params.page,
      perPage: params.perPage,
      query: params.query,
      forceRefresh: params.forceRefresh,
    );
  }
}

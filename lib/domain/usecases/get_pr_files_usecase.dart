import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../../core/usecases/usecase.dart';
import '../entities/file_change.dart';
import '../repositories/github_repository.dart';

class GetPRFilesParams extends Equatable {
  final String owner;
  final String repo;
  final int number;

  const GetPRFilesParams({
    required this.owner,
    required this.repo,
    required this.number,
  });

  @override
  List<Object?> get props => [owner, repo, number];
}

class GetPRFilesUseCase implements UseCase<List<FileChange>, GetPRFilesParams> {
  final GithubRepository repository;

  GetPRFilesUseCase(this.repository);

  @override
  Future<Either<Failure, List<FileChange>>> call(GetPRFilesParams params) async {
    return await repository.getPRFiles(
      owner: params.owner,
      repo: params.repo,
      number: params.number,
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../../core/usecases/usecase.dart';
import '../entities/review.dart';
import '../repositories/github_repository.dart';

class GetPRReviewsParams extends Equatable {
  final String owner;
  final String repo;
  final int number;

  const GetPRReviewsParams({
    required this.owner,
    required this.repo,
    required this.number,
  });

  @override
  List<Object?> get props => [owner, repo, number];
}

class GetPRReviewsUseCase implements UseCase<List<Review>, GetPRReviewsParams> {
  final GithubRepository repository;

  GetPRReviewsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Review>>> call(GetPRReviewsParams params) async {
    return await repository.getPRReviews(
      owner: params.owner,
      repo: params.repo,
      number: params.number,
    );
  }
}

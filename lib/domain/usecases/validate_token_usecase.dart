import 'package:fpdart/fpdart.dart';
import '../../core/error/failure.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/github_repository.dart';

class ValidateTokenUseCase implements UseCase<User, String> {
  final GithubRepository repository;

  ValidateTokenUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(String token) async {
    return await repository.validateToken(token);
  }
}

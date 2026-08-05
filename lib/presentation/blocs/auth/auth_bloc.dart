import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/validate_token_usecase.dart';
import '../../../domain/repositories/github_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ValidateTokenUseCase validateTokenUseCase;
  final GithubRepository repository;

  AuthBloc({
    required this.validateTokenUseCase,
    required this.repository,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SubmitTokenEvent>(_onSubmitToken);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final tokenResult = await repository.getSavedToken();

    await tokenResult.fold(
      (failure) async => emit(const Unauthenticated()),
      (token) async {
        if (token == null || token.isEmpty) {
          emit(const Unauthenticated());
        } else {
          final userResult = await validateTokenUseCase(token);
          userResult.fold(
            (failure) => emit(Unauthenticated(errorMessage: failure.message)),
            (user) => emit(Authenticated(user: user, token: token)),
          );
        }
      },
    );
  }

  Future<void> _onSubmitToken(
    SubmitTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await validateTokenUseCase(event.token.trim());

    await result.fold(
      (failure) async {
        emit(Unauthenticated(errorMessage: failure.message));
      },
      (user) async {
        await repository.saveToken(event.token.trim());
        emit(Authenticated(user: user, token: event.token.trim()));
      },
    );
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await repository.logout();
    emit(const Unauthenticated());
  }
}

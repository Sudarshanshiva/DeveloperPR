import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/github_remote_datasource.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GithubRemoteDataSource remoteDataSource;

  AuthBloc({
    required this.remoteDataSource,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SubmitUsernameEvent>(_onSubmitUsername);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const Unauthenticated());
  }

  Future<void> _onSubmitUsername(
    SubmitUsernameEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await remoteDataSource.getUserByUsername(event.username.trim());
      emit(Authenticated(user: user, username: event.username.trim()));
    } catch (e) {
      emit(Unauthenticated(errorMessage: 'User "${event.username}" not found. Please check the username.'));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const Unauthenticated());
  }
}

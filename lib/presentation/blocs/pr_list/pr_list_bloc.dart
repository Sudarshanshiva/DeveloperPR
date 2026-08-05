import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/github_remote_datasource.dart';
import '../../../domain/entities/pull_request.dart';

// Events
abstract class PRListEvent extends Equatable {
  const PRListEvent();
  @override
  List<Object?> get props => [];
}

class FetchPRsEvent extends PRListEvent {
  final String owner;
  final String repo;
  final String stateFilter;

  const FetchPRsEvent({
    required this.owner,
    required this.repo,
    this.stateFilter = 'open',
  });

  @override
  List<Object?> get props => [owner, repo, stateFilter];
}

// States
abstract class PRListState extends Equatable {
  const PRListState();
  @override
  List<Object?> get props => [];
}

class PRListInitial extends PRListState {}
class PRListLoading extends PRListState {}

class PRListLoaded extends PRListState {
  final List<PullRequest> pullRequests;
  final String owner;
  final String repo;
  final String activeStateFilter;

  const PRListLoaded({
    required this.pullRequests,
    required this.owner,
    required this.repo,
    required this.activeStateFilter,
  });

  @override
  List<Object?> get props => [pullRequests, owner, repo, activeStateFilter];
}

class PRListError extends PRListState {
  final String message;
  const PRListError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class PRListBloc extends Bloc<PRListEvent, PRListState> {
  final GithubRemoteDataSource remoteDataSource;

  PRListBloc({required this.remoteDataSource}) : super(PRListInitial()) {
    on<FetchPRsEvent>(_onFetchPRs);
  }

  Future<void> _onFetchPRs(
    FetchPRsEvent event,
    Emitter<PRListState> emit,
  ) async {
    emit(PRListLoading());
    try {
      final prs = await remoteDataSource.getPullRequests(
        owner: event.owner,
        repo: event.repo,
        state: event.stateFilter,
      );
      emit(PRListLoaded(
        pullRequests: prs,
        owner: event.owner,
        repo: event.repo,
        activeStateFilter: event.stateFilter,
      ));
    } catch (e) {
      emit(PRListError(e.toString()));
    }
  }
}

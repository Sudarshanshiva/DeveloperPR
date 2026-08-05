import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/github_remote_datasource.dart';
import '../../../domain/entities/repository.dart';

// Events
abstract class RepoListEvent extends Equatable {
  const RepoListEvent();

  @override
  List<Object?> get props => [];
}

class FetchReposEvent extends RepoListEvent {
  final String username;
  final bool forceRefresh;
  const FetchReposEvent({required this.username, this.forceRefresh = false});

  @override
  List<Object?> get props => [username, forceRefresh];
}

class LoadMoreReposEvent extends RepoListEvent {}

class SearchReposEvent extends RepoListEvent {
  final String query;
  const SearchReposEvent(this.query);

  @override
  List<Object?> get props => [query];
}

// States
abstract class RepoListState extends Equatable {
  const RepoListState();

  @override
  List<Object?> get props => [];
}

class RepoListInitial extends RepoListState {}

class RepoListLoading extends RepoListState {}

class RepoListLoaded extends RepoListState {
  final List<GithubRepo> repos;
  final List<GithubRepo> allRepos; // full list for local search
  final bool hasReachedMax;
  final int currentPage;
  final String username;
  final String? searchQuery;

  const RepoListLoaded({
    required this.repos,
    required this.allRepos,
    this.hasReachedMax = false,
    this.currentPage = 1,
    required this.username,
    this.searchQuery,
  });

  RepoListLoaded copyWith({
    List<GithubRepo>? repos,
    List<GithubRepo>? allRepos,
    bool? hasReachedMax,
    int? currentPage,
    String? username,
    String? searchQuery,
  }) {
    return RepoListLoaded(
      repos: repos ?? this.repos,
      allRepos: allRepos ?? this.allRepos,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      username: username ?? this.username,
      searchQuery: searchQuery,
    );
  }

  @override
  List<Object?> get props => [repos, allRepos, hasReachedMax, currentPage, username, searchQuery];
}

class RepoListError extends RepoListState {
  final String message;
  const RepoListError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class RepoListBloc extends Bloc<RepoListEvent, RepoListState> {
  final GithubRemoteDataSource remoteDataSource;

  RepoListBloc({required this.remoteDataSource}) : super(RepoListInitial()) {
    on<FetchReposEvent>(_onFetchRepos);
    on<LoadMoreReposEvent>(_onLoadMoreRepos);
    on<SearchReposEvent>(_onSearchRepos);
  }

  Future<void> _onFetchRepos(
    FetchReposEvent event,
    Emitter<RepoListState> emit,
  ) async {
    emit(RepoListLoading());
    try {
      final repos = await remoteDataSource.getUserRepositories(
        username: event.username,
        page: 1,
      );
      emit(
        RepoListLoaded(
          repos: repos,
          allRepos: repos,
          hasReachedMax: repos.length < 30,
          currentPage: 1,
          username: event.username,
        ),
      );
    } catch (e) {
      emit(RepoListError(e.toString()));
    }
  }

  Future<void> _onLoadMoreRepos(
    LoadMoreReposEvent event,
    Emitter<RepoListState> emit,
  ) async {
    if (state is! RepoListLoaded) return;
    final currentState = state as RepoListLoaded;
    if (currentState.hasReachedMax) return;

    final nextPage = currentState.currentPage + 1;
    try {
      final newRepos = await remoteDataSource.getUserRepositories(
        username: currentState.username,
        page: nextPage,
      );
      if (newRepos.isEmpty) {
        emit(currentState.copyWith(hasReachedMax: true));
      } else {
        final allRepos = [...currentState.allRepos, ...newRepos];
        emit(
          currentState.copyWith(
            repos: currentState.searchQuery != null
                ? allRepos
                    .where((r) => r.name.toLowerCase().contains(currentState.searchQuery!.toLowerCase()))
                    .toList()
                : allRepos,
            allRepos: allRepos,
            currentPage: nextPage,
            hasReachedMax: newRepos.length < 30,
          ),
        );
      }
    } catch (_) {
      emit(currentState);
    }
  }

  Future<void> _onSearchRepos(
    SearchReposEvent event,
    Emitter<RepoListState> emit,
  ) async {
    if (state is! RepoListLoaded) return;
    final currentState = state as RepoListLoaded;
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(currentState.copyWith(repos: currentState.allRepos, searchQuery: null));
    } else {
      final filtered = currentState.allRepos
          .where((r) => r.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      emit(currentState.copyWith(repos: filtered, searchQuery: query));
    }
  }
}

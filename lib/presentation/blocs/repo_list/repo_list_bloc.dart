import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_repos_usecase.dart';
import 'repo_list_event.dart';
import 'repo_list_state.dart';

class RepoListBloc extends Bloc<RepoListEvent, RepoListState> {
  final GetReposUseCase getReposUseCase;

  RepoListBloc({required this.getReposUseCase}) : super(RepoListInitial()) {
    on<FetchReposEvent>(_onFetchRepos);
    on<LoadMoreReposEvent>(_onLoadMoreRepos);
    on<SearchReposEvent>(_onSearchRepos);
  }

  Future<void> _onFetchRepos(
    FetchReposEvent event,
    Emitter<RepoListState> emit,
  ) async {
    emit(RepoListLoading());
    final result = await getReposUseCase(
      GetReposParams(page: 1, forceRefresh: event.forceRefresh),
    );

    result.fold(
      (failure) => emit(RepoListError(failure.message)),
      (repos) => emit(
        RepoListLoaded(
          repos: repos,
          hasReachedMax: repos.length < 30,
          currentPage: 1,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreRepos(
    LoadMoreReposEvent event,
    Emitter<RepoListState> emit,
  ) async {
    if (state is! RepoListLoaded) return;
    final currentState = state as RepoListLoaded;
    if (currentState.hasReachedMax) return;

    final nextPage = currentState.currentPage + 1;
    final result = await getReposUseCase(
      GetReposParams(page: nextPage, query: currentState.searchQuery),
    );

    result.fold(
      (failure) => emit(currentState),
      (newRepos) {
        if (newRepos.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          emit(
            currentState.copyWith(
              repos: [...currentState.repos, ...newRepos],
              currentPage: nextPage,
              hasReachedMax: newRepos.length < 30,
            ),
          );
        }
      },
    );
  }

  Future<void> _onSearchRepos(
    SearchReposEvent event,
    Emitter<RepoListState> emit,
  ) async {
    emit(RepoListLoading());
    final query = event.query.trim();

    final result = await getReposUseCase(
      GetReposParams(page: 1, query: query.isEmpty ? null : query),
    );

    result.fold(
      (failure) => emit(RepoListError(failure.message)),
      (repos) => emit(
        RepoListLoaded(
          repos: repos,
          hasReachedMax: repos.length < 30,
          currentPage: 1,
          searchQuery: query.isEmpty ? null : query,
        ),
      ),
    );
  }
}

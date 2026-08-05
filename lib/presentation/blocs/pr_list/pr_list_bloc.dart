import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_pull_requests_usecase.dart';
import 'pr_list_event.dart';
import 'pr_list_state.dart';

class PRListBloc extends Bloc<PRListEvent, PRListState> {
  final GetPullRequestsUseCase getPullRequestsUseCase;

  PRListBloc({required this.getPullRequestsUseCase}) : super(PRListInitial()) {
    on<FetchPRsEvent>(_onFetchPRs);
    on<ChangePRStateFilterEvent>(_onChangePRStateFilter);
  }

  Future<void> _onFetchPRs(
    FetchPRsEvent event,
    Emitter<PRListState> emit,
  ) async {
    emit(PRListLoading());
    final result = await getPullRequestsUseCase(
      GetPRsParams(
        owner: event.owner,
        repo: event.repo,
        state: event.stateFilter,
        forceRefresh: event.forceRefresh,
      ),
    );

    result.fold(
      (failure) => emit(PRListError(failure.message)),
      (prs) => emit(
        PRListLoaded(
          pullRequests: prs,
          owner: event.owner,
          repo: event.repo,
          activeStateFilter: event.stateFilter,
        ),
      ),
    );
  }

  Future<void> _onChangePRStateFilter(
    ChangePRStateFilterEvent event,
    Emitter<PRListState> emit,
  ) async {
    if (state is! PRListLoaded) return;
    final currentState = state as PRListLoaded;

    add(
      FetchPRsEvent(
        owner: currentState.owner,
        repo: currentState.repo,
        stateFilter: event.stateFilter,
        forceRefresh: true,
      ),
    );
  }
}

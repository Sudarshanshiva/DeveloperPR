import 'package:equatable/equatable.dart';

abstract class RepoListEvent extends Equatable {
  const RepoListEvent();

  @override
  List<Object?> get props => [];
}

class FetchReposEvent extends RepoListEvent {
  final bool forceRefresh;
  const FetchReposEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadMoreReposEvent extends RepoListEvent {}

class SearchReposEvent extends RepoListEvent {
  final String query;
  const SearchReposEvent(this.query);

  @override
  List<Object?> get props => [query];
}

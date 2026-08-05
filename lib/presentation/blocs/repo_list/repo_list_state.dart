import 'package:equatable/equatable.dart';
import '../../../domain/entities/repository.dart';

abstract class RepoListState extends Equatable {
  const RepoListState();

  @override
  List<Object?> get props => [];
}

class RepoListInitial extends RepoListState {}

class RepoListLoading extends RepoListState {}

class RepoListLoaded extends RepoListState {
  final List<GithubRepo> repos;
  final bool hasReachedMax;
  final int currentPage;
  final String? searchQuery;
  final bool isFromCache;

  const RepoListLoaded({
    required this.repos,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.searchQuery,
    this.isFromCache = false,
  });

  RepoListLoaded copyWith({
    List<GithubRepo>? repos,
    bool? hasReachedMax,
    int? currentPage,
    String? searchQuery,
    bool? isFromCache,
  }) {
    return RepoListLoaded(
      repos: repos ?? this.repos,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => [repos, hasReachedMax, currentPage, searchQuery, isFromCache];
}

class RepoListError extends RepoListState {
  final String message;
  const RepoListError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../../domain/entities/pull_request.dart';

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

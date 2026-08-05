import 'package:equatable/equatable.dart';

abstract class PRListEvent extends Equatable {
  const PRListEvent();

  @override
  List<Object?> get props => [];
}

class FetchPRsEvent extends PRListEvent {
  final String owner;
  final String repo;
  final String stateFilter; // 'open', 'closed', 'all'
  final bool forceRefresh;

  const FetchPRsEvent({
    required this.owner,
    required this.repo,
    this.stateFilter = 'open',
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [owner, repo, stateFilter, forceRefresh];
}

class ChangePRStateFilterEvent extends PRListEvent {
  final String stateFilter;
  const ChangePRStateFilterEvent(this.stateFilter);

  @override
  List<Object?> get props => [stateFilter];
}

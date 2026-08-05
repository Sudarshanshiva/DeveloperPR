import 'package:equatable/equatable.dart';

abstract class PRDetailEvent extends Equatable {
  const PRDetailEvent();

  @override
  List<Object?> get props => [];
}

class FetchPRDetailEvent extends PRDetailEvent {
  final String owner;
  final String repo;
  final int number;

  const FetchPRDetailEvent({
    required this.owner,
    required this.repo,
    required this.number,
  });

  @override
  List<Object?> get props => [owner, repo, number];
}

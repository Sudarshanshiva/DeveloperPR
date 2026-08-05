import 'package:equatable/equatable.dart';
import '../../../domain/entities/file_change.dart';
import '../../../domain/entities/pull_request.dart';
import '../../../domain/entities/review.dart';

abstract class PRDetailState extends Equatable {
  const PRDetailState();

  @override
  List<Object?> get props => [];
}

class PRDetailInitial extends PRDetailState {}

class PRDetailLoading extends PRDetailState {}

class PRDetailLoaded extends PRDetailState {
  final PullRequest pullRequest;
  final List<FileChange> files;
  final List<Review> reviews;

  const PRDetailLoaded({
    required this.pullRequest,
    required this.files,
    required this.reviews,
  });

  @override
  List<Object?> get props => [pullRequest, files, reviews];
}

class PRDetailError extends PRDetailState {
  final String message;
  const PRDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

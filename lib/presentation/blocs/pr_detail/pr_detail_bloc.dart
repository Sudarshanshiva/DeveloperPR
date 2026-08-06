import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/github_remote_datasource.dart';
import '../../../domain/entities/file_change.dart';
import '../../../domain/entities/pull_request.dart';
import '../../../domain/entities/review.dart';

// Events
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

// States
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

// BLoC
class PRDetailBloc extends Bloc<PRDetailEvent, PRDetailState> {
  final GithubRemoteDataSource remoteDataSource;

  PRDetailBloc({required this.remoteDataSource}) : super(PRDetailInitial()) {
    on<FetchPRDetailEvent>(_onFetchPRDetail);
  }

  Future<void> _onFetchPRDetail(
    FetchPRDetailEvent event,
    Emitter<PRDetailState> emit,
  ) async {
    emit(PRDetailLoading());
    try {
      final pr = await remoteDataSource.getPullRequestDetails(
        owner: event.owner,
        repo: event.repo,
        number: event.number,
      );

      List<FileChange> files = [];
      List<Review> reviews = [];

      try {
        files = await remoteDataSource.getPRFiles(
          owner: event.owner,
          repo: event.repo,
          number: event.number,
        );
      } catch (_) {}

      try {
        reviews = await remoteDataSource.getPRReviews(
          owner: event.owner,
          repo: event.repo,
          number: event.number,
        );
      } catch (_) {}

      emit(PRDetailLoaded(pullRequest: pr, files: files, reviews: reviews));
    } catch (e) {
      emit(PRDetailError(e.toString()));
    }
  }
}

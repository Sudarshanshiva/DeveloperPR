import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_pr_details_usecase.dart';
import '../../../domain/usecases/get_pr_files_usecase.dart';
import '../../../domain/usecases/get_pr_reviews_usecase.dart';
import 'pr_detail_event.dart';
import 'pr_detail_state.dart';

class PRDetailBloc extends Bloc<PRDetailEvent, PRDetailState> {
  final GetPRDetailsUseCase getPRDetailsUseCase;
  final GetPRFilesUseCase getPRFilesUseCase;
  final GetPRReviewsUseCase getPRReviewsUseCase;

  PRDetailBloc({
    required this.getPRDetailsUseCase,
    required this.getPRFilesUseCase,
    required this.getPRReviewsUseCase,
  }) : super(PRDetailInitial()) {
    on<FetchPRDetailEvent>(_onFetchPRDetail);
  }

  Future<void> _onFetchPRDetail(
    FetchPRDetailEvent event,
    Emitter<PRDetailState> emit,
  ) async {
    emit(PRDetailLoading());

    final detailResult = await getPRDetailsUseCase(
      GetPRDetailsParams(owner: event.owner, repo: event.repo, number: event.number),
    );

    await detailResult.fold(
      (failure) async => emit(PRDetailError(failure.message)),
      (pr) async {
        final filesResult = await getPRFilesUseCase(
          GetPRFilesParams(owner: event.owner, repo: event.repo, number: event.number),
        );
        final reviewsResult = await getPRReviewsUseCase(
          GetPRReviewsParams(owner: event.owner, repo: event.repo, number: event.number),
        );

        final files = filesResult.getOrElse((_) => []);
        final reviews = reviewsResult.getOrElse((_) => []);

        emit(
          PRDetailLoaded(
            pullRequest: pr,
            files: files,
            reviews: reviews,
          ),
        );
      },
    );
  }
}

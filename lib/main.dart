import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/cache/hive_cache_manager.dart';
import 'core/network/dio_client.dart';
import 'core/network/interceptors.dart';
import 'core/network/network_info.dart';
import 'core/theme/app_theme.dart';

import 'data/datasources/github_local_datasource.dart';
import 'data/datasources/github_remote_datasource.dart';
import 'data/repositories/github_repository_impl.dart';

import 'domain/repositories/github_repository.dart';
import 'domain/usecases/get_pr_details_usecase.dart';
import 'domain/usecases/get_pr_files_usecase.dart';
import 'domain/usecases/get_pr_reviews_usecase.dart';
import 'domain/usecases/get_pull_requests_usecase.dart';
import 'domain/usecases/get_repos_usecase.dart';
import 'domain/usecases/validate_token_usecase.dart';

import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/connectivity/connectivity_cubit.dart';
import 'presentation/blocs/repo_list/repo_list_bloc.dart';
import 'presentation/blocs/theme/theme_cubit.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/repo_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive Offline Storage
  await HiveCacheManager.init();

  // Instantiate Core Services & Dependencies
  final secureStorage = const FlutterSecureStorage();
  final cacheManager = HiveCacheManager();
  final connectivity = Connectivity();
  final networkInfo = NetworkInfoImpl(connectivity);

  final localDataSource = GithubLocalDataSourceImpl(
    secureStorage: secureStorage,
    cacheManager: cacheManager,
  );

  final rateLimitNotifier = RateLimitNotifier();

  final dioClient = DioClient(
    getToken: () async => await localDataSource.getToken(),
    rateLimitNotifier: rateLimitNotifier,
  );

  final remoteDataSource = GithubRemoteDataSourceImpl(dio: dioClient.dio);

  final repository = GithubRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
  );

  // UseCases
  final validateTokenUseCase = ValidateTokenUseCase(repository);
  final getReposUseCase = GetReposUseCase(repository);
  final getPullRequestsUseCase = GetPullRequestsUseCase(repository);
  final getPRDetailsUseCase = GetPRDetailsUseCase(repository);
  final getPRFilesUseCase = GetPRFilesUseCase(repository);
  final getPRReviewsUseCase = GetPRReviewsUseCase(repository);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<GithubRepository>.value(value: repository),
        RepositoryProvider<GetReposUseCase>.value(value: getReposUseCase),
        RepositoryProvider<GetPullRequestsUseCase>.value(value: getPullRequestsUseCase),
        RepositoryProvider<GetPRDetailsUseCase>.value(value: getPRDetailsUseCase),
        RepositoryProvider<GetPRFilesUseCase>.value(value: getPRFilesUseCase),
        RepositoryProvider<GetPRReviewsUseCase>.value(value: getPRReviewsUseCase),
        RepositoryProvider<RateLimitNotifier>.value(value: rateLimitNotifier),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => ConnectivityCubit(networkInfo: networkInfo)),
          BlocProvider(
            create: (_) => AuthBloc(
              validateTokenUseCase: validateTokenUseCase,
              repository: repository,
            )..add(CheckAuthStatusEvent()),
          ),
          BlocProvider(
            create: (_) => RepoListBloc(getReposUseCase: getReposUseCase),
          ),
        ],
        child: PRDashboardApp(rateLimitNotifier: rateLimitNotifier),
      ),
    ),
  );
}

class PRDashboardApp extends StatelessWidget {
  final RateLimitNotifier rateLimitNotifier;

  const PRDashboardApp({super.key, required this.rateLimitNotifier});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          title: 'GitHub PR Dashboard',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return RepoListScreen(rateLimitNotifier: rateLimitNotifier);
              }
              if (state is AuthLoading || state is AuthInitial) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}

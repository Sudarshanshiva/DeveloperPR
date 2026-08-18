import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/cache/hive_cache_manager.dart';
import 'core/network/dio_client.dart';
import 'core/network/interceptors.dart';
import 'core/network/network_info.dart';
import 'core/theme/app_theme.dart';

import 'data/datasources/ai_remote_datasource.dart';
import 'data/datasources/github_remote_datasource.dart';
import 'data/repositories/ai_analysis_repository_impl.dart';

import 'domain/repositories/ai_analysis_repository.dart';
import 'domain/usecases/analyze_pull_request_usecase.dart';

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

  final connectivity = Connectivity();
  final networkInfo = NetworkInfoImpl(connectivity);
  final rateLimitNotifier = RateLimitNotifier();
  const secureStorage = FlutterSecureStorage();
  final cacheManager = HiveCacheManager();

  // No auth token needed for GitHub — public GitHub API
  final dioClient = DioClient(
    getToken: () async => null,
    rateLimitNotifier: rateLimitNotifier,
  );

  final remoteDataSource = GithubRemoteDataSourceImpl(dio: dioClient.dio);
  final aiRemoteDataSource = AiRemoteDataSourceImpl(dio: dioClient.dio);
  final aiAnalysisRepository = AiAnalysisRepositoryImpl(
    remoteDataSource: aiRemoteDataSource,
    cacheManager: cacheManager,
    secureStorage: secureStorage,
  );
  final analyzePullRequestUseCase = AnalyzePullRequestUseCase(aiAnalysisRepository);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<GithubRemoteDataSource>.value(value: remoteDataSource),
        RepositoryProvider<RateLimitNotifier>.value(value: rateLimitNotifier),
        RepositoryProvider<AiAnalysisRepository>.value(value: aiAnalysisRepository),
        RepositoryProvider<AnalyzePullRequestUseCase>.value(value: analyzePullRequestUseCase),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => ConnectivityCubit(networkInfo: networkInfo)),
          BlocProvider(
            create: (_) => AuthBloc(
              remoteDataSource: remoteDataSource,
            )..add(CheckAuthStatusEvent()),
          ),
          BlocProvider(
            create: (_) => RepoListBloc(remoteDataSource: remoteDataSource),
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

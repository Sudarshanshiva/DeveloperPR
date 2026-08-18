import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/network/interceptors.dart';
import '../../data/datasources/github_remote_datasource.dart';
import '../../domain/repositories/ai_analysis_repository.dart';
import '../../domain/usecases/analyze_pull_request_usecase.dart';
import '../blocs/ai_analysis/ai_analysis_bloc.dart';
import '../blocs/pr_detail/pr_detail_bloc.dart';
import '../widgets/ai_review_tab.dart';
import '../widgets/file_diff_tile.dart';
import '../widgets/offline_banner.dart';
import '../widgets/pr_status_badge.dart';
import '../widgets/pr_summary_breakdown.dart';
import '../widgets/rate_limit_banner.dart';
import '../widgets/reviewer_tile.dart';

class PRDetailScreen extends StatelessWidget {
  final String owner;
  final String repoName;
  final int prNumber;
  final RateLimitNotifier rateLimitNotifier;

  const PRDetailScreen({
    super.key,
    required this.owner,
    required this.repoName,
    required this.prNumber,
    required this.rateLimitNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PRDetailBloc(
            remoteDataSource: context.read<GithubRemoteDataSource>(),
          )..add(FetchPRDetailEvent(owner: owner, repo: repoName, number: prNumber)),
        ),
        BlocProvider(
          create: (context) => AiAnalysisBloc(
            repository: context.read<AiAnalysisRepository>(),
            analyzePullRequestUseCase: context.read<AnalyzePullRequestUseCase>(),
          ),
        ),
      ],
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text('#$prNumber in $repoName'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Overview', icon: Icon(Icons.description_rounded, size: 18)),
                Tab(text: 'Files', icon: Icon(Icons.code_rounded, size: 18)),
                Tab(text: 'Reviews', icon: Icon(Icons.rate_review_rounded, size: 18)),
                Tab(text: 'AI Review', icon: Icon(Icons.auto_awesome_rounded, size: 18)),
              ],
            ),
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              RateLimitBanner(rateLimitNotifier: rateLimitNotifier),
              Expanded(
                child: BlocBuilder<PRDetailBloc, PRDetailState>(
                  builder: (context, state) {
                    if (state is PRDetailLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is PRDetailError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(state.message, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is PRDetailLoaded) {
                      final pr = state.pullRequest;
                      return TabBarView(
                        children: [
                          // ─── Tab 1: Overview ───
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    PRStatusBadge(state: pr.state, isDraft: pr.isDraft),
                                    const SizedBox(width: 8),
                                    if (pr.ciState != null) CIBadge(ciState: pr.ciState),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  pr.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundImage: pr.authorAvatar.isNotEmpty
                                          ? NetworkImage(pr.authorAvatar)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(pr.authorLogin,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${pr.headBranch} → ${pr.baseBranch}',
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Stats row
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Theme.of(context).dividerColor),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _stat('Files', '${state.files.length}', Colors.blue),
                                      _stat('+Added', '+${pr.additions}', Colors.green),
                                      _stat('-Removed', '-${pr.deletions}', Colors.red),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text('Description',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Divider(),
                                const SizedBox(height: 8),
                                pr.body != null && pr.body!.isNotEmpty
                                    ? MarkdownBody(data: pr.body!, selectable: true)
                                    : const Text('No description provided.',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic, color: Colors.grey)),
                                const SizedBox(height: 24),
                                PRSummaryBreakdown(
                                  pullRequest: pr,
                                  files: state.files,
                                  prKey: '${owner}_${repoName}_${pr.number}',
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),

                          // ─── Tab 2: Files Changed ───
                          state.files.isEmpty
                              ? const Center(child: Text('No file changes.'))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.files.length,
                                  itemBuilder: (context, i) =>
                                      FileDiffTile(file: state.files[i]),
                                ),

                          // ─── Tab 3: Reviews ───
                          state.reviews.isEmpty
                              ? const Center(
                                  child: Text('No reviews yet.',
                                      style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.reviews.length,
                                  itemBuilder: (context, i) =>
                                      ReviewerTile(review: state.reviews[i]),
                                ),

                          // ─── Tab 4: AI Review ───
                          AIReviewTab(
                            owner: owner,
                            repoName: repoName,
                            prNumber: prNumber,
                            prTitle: pr.title,
                            prDescription: pr.body,
                            files: state.files,
                          ),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

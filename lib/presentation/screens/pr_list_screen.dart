import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/network/interceptors.dart';
import '../../data/datasources/github_remote_datasource.dart';
import '../../domain/entities/pull_request.dart';
import '../blocs/pr_list/pr_list_bloc.dart';
import '../widgets/offline_banner.dart';
import '../widgets/pr_status_badge.dart';
import '../widgets/rate_limit_banner.dart';
import '../widgets/shimmer_skeleton.dart';
import 'pr_detail_screen.dart';

class PRListScreen extends StatelessWidget {
  final String owner;
  final String repoName;
  final RateLimitNotifier rateLimitNotifier;

  const PRListScreen({
    super.key,
    required this.owner,
    required this.repoName,
    required this.rateLimitNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PRListBloc(
        remoteDataSource: context.read<GithubRemoteDataSource>(),
      )..add(FetchPRsEvent(owner: owner, repo: repoName, stateFilter: 'open')),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$owner / $repoName',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const Text('Pull Requests', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            RateLimitBanner(rateLimitNotifier: rateLimitNotifier),
            _FilterChipsBar(owner: owner, repoName: repoName),
            Expanded(
              child: BlocBuilder<PRListBloc, PRListState>(
                builder: (context, state) {
                  if (state is PRListLoading) {
                    return const ShimmerListSkeleton();
                  }

                  if (state is PRListError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            Text(state.message, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.read<PRListBloc>().add(
                                    FetchPRsEvent(owner: owner, repo: repoName),
                                  ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is PRListLoaded) {
                    if (state.pullRequests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.green),
                            SizedBox(height: 12),
                            Text(
                              'No Pull Requests found 🎉',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => context.read<PRListBloc>().add(
                            FetchPRsEvent(
                              owner: owner,
                              repo: repoName,
                              stateFilter: state.activeStateFilter,
                            ),
                          ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: state.pullRequests.length,
                        itemBuilder: (context, index) {
                          return _buildPRCard(context, state.pullRequests[index]);
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPRCard(BuildContext context, PullRequest pr) {
    final dateFormat = DateFormat.yMMMd();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PRDetailScreen(
              owner: owner,
              repoName: repoName,
              prNumber: pr.number,
              rateLimitNotifier: rateLimitNotifier,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PRStatusBadge(state: pr.state, isDraft: pr.isDraft),
                  const SizedBox(width: 8),
                  Text('#${pr.number}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(pr.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage:
                        pr.authorAvatar.isNotEmpty ? NetworkImage(pr.authorAvatar) : null,
                  ),
                  const SizedBox(width: 6),
                  Text(pr.authorLogin,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  const Icon(Icons.fork_right_rounded, size: 14, color: Colors.indigoAccent),
                  Expanded(
                    child: Text(
                      '${pr.headBranch} → ${pr.baseBranch}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Opened ${dateFormat.format(pr.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (pr.ciState != null) CIBadge(ciState: pr.ciState),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipsBar extends StatelessWidget {
  final String owner;
  final String repoName;

  const _FilterChipsBar({required this.owner, required this.repoName});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PRListBloc, PRListState>(
      builder: (context, state) {
        final activeFilter = state is PRListLoaded ? state.activeStateFilter : 'open';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _chip(context, 'Open', 'open', activeFilter),
              const SizedBox(width: 8),
              _chip(context, 'Closed', 'closed', activeFilter),
              const SizedBox(width: 8),
              _chip(context, 'All', 'all', activeFilter),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(BuildContext context, String label, String value, String active) {
    return ChoiceChip(
      label: Text(label),
      selected: active == value,
      onSelected: (selected) {
        if (selected) {
          context.read<PRListBloc>().add(
                FetchPRsEvent(owner: owner, repo: repoName, stateFilter: value),
              );
        }
      },
    );
  }
}

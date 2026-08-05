import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/network/interceptors.dart';
import '../../domain/entities/repository.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/repo_list/repo_list_bloc.dart';
import '../blocs/repo_list/repo_list_event.dart';
import '../blocs/repo_list/repo_list_state.dart';
import '../blocs/theme/theme_cubit.dart';
import '../widgets/offline_banner.dart';
import '../widgets/rate_limit_banner.dart';
import '../widgets/shimmer_skeleton.dart';
import 'pr_list_screen.dart';

class RepoListScreen extends StatefulWidget {
  final RateLimitNotifier rateLimitNotifier;

  const RepoListScreen({super.key, required this.rateLimitNotifier});

  @override
  State<RepoListScreen> createState() => _RepoListScreenState();
}

class _RepoListScreenState extends State<RepoListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RepoListBloc>().add(const FetchReposEvent());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<RepoListBloc>().add(LoadMoreReposEvent());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.watch<AuthBloc>().state as Authenticated).user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
              child: user.avatarUrl.isEmpty ? Text(user.login[0].toUpperCase()) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${user.login}\'s Repos',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutEvent());
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          RateLimitBanner(rateLimitNotifier: widget.rateLimitNotifier),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search repositories...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          context.read<RepoListBloc>().add(const SearchReposEvent(''));
                        },
                      )
                    : null,
              ),
              onChanged: (query) {
                context.read<RepoListBloc>().add(SearchReposEvent(query));
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<RepoListBloc, RepoListState>(
              builder: (context, state) {
                if (state is RepoListLoading) {
                  return const ShimmerListSkeleton();
                }

                if (state is RepoListError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<RepoListBloc>().add(const FetchReposEvent(forceRefresh: true));
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is RepoListLoaded) {
                  if (state.repos.isEmpty) {
                    return const Center(
                      child: Text('No repositories found 📦', style: TextStyle(fontSize: 16)),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<RepoListBloc>().add(const FetchReposEvent(forceRefresh: true));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: state.repos.length + (state.hasReachedMax ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index >= state.repos.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final repo = state.repos[index];
                        return _buildRepoCard(context, repo);
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
    );
  }

  Widget _buildRepoCard(BuildContext context, GithubRepo repo) {
    final dateFormat = DateFormat.yMMMd();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PRListScreen(
                owner: repo.owner,
                repoName: repo.name,
                rateLimitNotifier: widget.rateLimitNotifier,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    repo.isPrivate ? Icons.lock_outline_rounded : Icons.folder_open_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      repo.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
              if (repo.description != null && repo.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  repo.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  if (repo.language != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.code_rounded, size: 14, color: Colors.blueAccent),
                        const SizedBox(width: 4),
                        Text(repo.language!, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_border_rounded, size: 15, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${repo.stargazersCount}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.adjust_rounded, size: 14, color: Colors.orangeAccent),
                      const SizedBox(width: 4),
                      Text('${repo.openIssuesCount} issues/PRs', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text(
                    'Updated ${dateFormat.format(repo.updatedAt)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

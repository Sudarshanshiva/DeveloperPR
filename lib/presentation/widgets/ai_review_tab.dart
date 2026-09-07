import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/file_change.dart';
import '../../domain/entities/pr_analysis.dart';
import '../../domain/entities/user_quota.dart';
import '../blocs/ai_analysis/ai_analysis_bloc.dart';
import '../blocs/ai_analysis/ai_analysis_event.dart';
import '../blocs/ai_analysis/ai_analysis_state.dart';
import 'premium_upgrade_modal.dart';

class AIReviewTab extends StatefulWidget {
  final String owner;
  final String repoName;
  final int prNumber;
  final String prTitle;
  final String? prDescription;
  final List<FileChange> files;

  const AIReviewTab({
    super.key,
    required this.owner,
    required this.repoName,
    required this.prNumber,
    required this.prTitle,
    this.prDescription,
    required this.files,
  });

  @override
  State<AIReviewTab> createState() => _AIReviewTabState();
}

class _AIReviewTabState extends State<AIReviewTab> {
  final _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AiAnalysisBloc>().add(CheckAiApiKeyStatusEvent());
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BlocConsumer<AiAnalysisBloc, AiAnalysisState>(
        listener: (context, state) {
          if (state is AiAnalysisQuotaExceededState) {
            PremiumUpgradeModal.show(context, state.quota);
          }
        },
        builder: (context, state) {
          if (state is AiAnalysisInitial) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is AiAnalysisNoKeyConfigured) {
            return _buildApiKeySetupCard(context, provider: state.provider);
          }

          if (state is AiAnalysisReadyToAnalyze) {
            return _buildReadyToAnalyzeCard(context, provider: state.provider, quota: state.quota);
          }

          if (state is AiAnalysisQuotaExceededState) {
            return _buildQuotaExceededCard(context, quota: state.quota);
          }

          if (state is AiAnalysisLoading) {
            return _buildLoadingCard(context, message: state.message);
          }

          if (state is AiAnalysisLoaded) {
            return _buildAnalysisResultsView(context, result: state.result, provider: state.provider, quota: state.quota);
          }

          if (state is AiAnalysisError) {
            return _buildErrorView(context, state: state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildApiKeySetupCard(BuildContext context, {required String provider}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Configure Google Gemini AI',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Add your Google Gemini API key to enable automated PR code reviews, risk level detection, bug flagging, and test coverage suggestions.',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8), height: 1.4),
            ),
            const SizedBox(height: 12),
            // Free badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star_rounded, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Google Gemini is 100% FREE — Get key in 5 secs with zero credit card required!',
                      style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _keyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key (AIzaSy...)',
                hintText: 'AIzaSy...',
                prefixIcon: Icon(Icons.key_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            InkWell(
              onTap: () => launchUrl(Uri.parse('https://aistudio.google.com/app/apikey')),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Get your FREE Gemini API Key from Google AI Studio →',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                final key = _keyController.text.trim();
                if (key.isNotEmpty) {
                  context.read<AiAnalysisBloc>().add(
                        SaveAiApiKeyEvent(apiKey: key, provider: 'gemini'),
                      );
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Key & Continue'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'Stored locally via encrypted storage (Never leaves device)',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaBadge(UserQuota quota) {
    if (quota.isProMember) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.amber),
            SizedBox(width: 6),
            Text(
              'PRO MEMBER · UNLIMITED AI REVIEWS',
              style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (quota.hasCustomKey) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.key_rounded, size: 14, color: Colors.green),
            SizedBox(width: 6),
            Text(
              'CUSTOM KEY · UNLIMITED FREE REVIEWS',
              style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final remaining = quota.remainingFree;
    final isLow = remaining <= 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isLow ? Colors.orange : Colors.blue).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isLow ? Colors.orange : Colors.blue).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: isLow ? Colors.orange : Colors.blue),
          const SizedBox(width: 6),
          Text(
            '⚡ $remaining / ${quota.maxDailyFree} FREE DAILY REVIEWS LEFT',
            style: TextStyle(
              fontSize: 11,
              color: isLow ? Colors.orange : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyToAnalyzeCard(BuildContext context, {required String provider, required UserQuota quota}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildQuotaBadge(quota),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI Code Review Ready',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyze ${widget.files.length} changed files with Google Gemini 1.5 Flash (100% Free) for security vulnerabilities, memory leaks, architectural risks, and test coverage.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AiAnalysisBloc>().add(
                      RunAiAnalysisEvent(
                        owner: widget.owner,
                        repo: widget.repoName,
                        prNumber: widget.prNumber,
                        files: widget.files,
                        prTitle: widget.prTitle,
                        prDescription: widget.prDescription,
                      ),
                    );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Analyze PR with AI'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => PremiumUpgradeModal.show(context, quota),
              icon: const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.amber),
              label: const Text('Upgrade to Pro / API Settings', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotaExceededCard(BuildContext context, {required UserQuota quota}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Daily Free AI Quota Used (3/3)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have reached your 3 free daily AI reviews limit. Upgrade to Pro for unlimited reviews or bring your own free Gemini API key!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => PremiumUpgradeModal.show(context, quota),
              icon: const Icon(Icons.bolt_rounded),
              label: const Text('Unlock Unlimited AI Reviews'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context, {required String message}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Inspecting file diffs, checking logic safety & generating structured feedback...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResultsView(
    BuildContext context, {
    required PRAnalysisResult result,
    required String provider,
    required UserQuota quota,
  }) {
    final isLowRisk = result.riskLevel == 'low';
    final isMediumRisk = result.riskLevel == 'medium';
    final riskColor = isLowRisk
        ? Colors.green
        : isMediumRisk
            ? Colors.orange
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Risk Level & Header ───
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLowRisk
                        ? Icons.verified_user_rounded
                        : isMediumRisk
                            ? Icons.warning_amber_rounded
                            : Icons.gpp_bad_rounded,
                    color: riskColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Risk Level: ',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: riskColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              result.riskLevel.toUpperCase(),
                              style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analyzed ${result.analyzedFileCount} files · ${provider == 'gemini' ? 'Gemini 1.5 Flash' : provider == 'groq' ? 'Groq Llama 3.1' : provider == 'claude' ? 'Claude 3.5' : 'GPT-3.5'}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Re-analyze PR',
                  onPressed: () {
                    context.read<AiAnalysisBloc>().add(
                          RunAiAnalysisEvent(
                            owner: widget.owner,
                            repo: widget.repoName,
                            prNumber: widget.prNumber,
                            files: widget.files,
                            prTitle: widget.prTitle,
                            prDescription: widget.prDescription,
                            forceRefresh: true,
                          ),
                        );
                  },
                ),
              ],
            ),
          ),
        ),

        // Truncation Notice
        if (result.isTruncated) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Large PR diff truncated gracefully — analysis based on top ${result.analyzedFileCount} changed files.',
                    style: const TextStyle(fontSize: 11, color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // ─── Summary Card ───
        const Text('Executive Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(data: result.summary, selectable: true),
          ),
        ),

        const SizedBox(height: 16),

        // ─── Potential Issues Section ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Potential Issues Flagged', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: result.potentialIssues.isEmpty ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${result.potentialIssues.length}',
                style: TextStyle(
                  color: result.potentialIssues.isEmpty ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (result.potentialIssues.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No critical security vulnerabilities or bugs flagged by AI.',
                      style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...result.potentialIssues.map((issue) => _buildIssueCard(context, issue)),

        const SizedBox(height: 16),

        // ─── Improvement Suggestions Section ───
        if (result.suggestions.isNotEmpty) ...[
          const Text('Improvement Suggestions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.suggestions
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Expanded(
                              child: Text(s, style: const TextStyle(fontSize: 13, height: 1.35)),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ─── Test Coverage Section ───
        const Text('Test Coverage & Adequacy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  result.testCoverage.toLowerCase().contains('no test') || result.testCoverage.toLowerCase().contains('lacks')
                      ? Icons.science_outlined
                      : Icons.science_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.testCoverage,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () => PremiumUpgradeModal.show(context, quota),
            icon: const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.amber),
            label: const Text('Upgrade to Pro / API Settings', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildIssueCard(BuildContext context, PRPotentialIssue issue) {
    final isHigh = issue.severity == 'high';
    final isMed = issue.severity == 'medium';
    final color = isHigh
        ? Colors.red
        : isMed
            ? Colors.orange
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    issue.severity.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    issue.file,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (issue.line != null)
                  Text(
                    'Line ${issue.line}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              issue.issue,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, {required AiAnalysisError state}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (state.isAuthError) {
                  context.read<AiAnalysisBloc>().add(DeleteAiApiKeyEvent());
                } else {
                  context.read<AiAnalysisBloc>().add(
                        RunAiAnalysisEvent(
                          owner: widget.owner,
                          repo: widget.repoName,
                          prNumber: widget.prNumber,
                          files: widget.files,
                          prTitle: widget.prTitle,
                          prDescription: widget.prDescription,
                          forceRefresh: true,
                        ),
                      );
                }
              },
              icon: Icon(state.isAuthError ? Icons.settings_rounded : Icons.refresh_rounded),
              label: Text(state.isAuthError ? 'Re-configure API Key' : 'Retry Analysis'),
            ),
          ],
        ),
      ),
    );
  }
}

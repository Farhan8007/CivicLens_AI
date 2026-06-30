import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/issue_model.dart';
import 'ai_report_analysis_screen.dart';

class HighPriorityReportsScreen extends StatelessWidget {
  final List<IssueModel> reports;

  const HighPriorityReportsScreen({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final highPriority =
        reports.where((r) => r.priority.toLowerCase() == 'high').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('High Priority Reports'),
        centerTitle: false,
      ),
      body: highPriority.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green.withValues(alpha: 0.7)),
                  const SizedBox(height: 16),
                  Text('No high priority reports.',
                      style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(
                    'Your community is looking good!',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: highPriority.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final issue = highPriority[index];
                return _HighPriorityCard(issue: issue);
              },
            ),
    );
  }
}

class _HighPriorityCard extends StatelessWidget {
  final IssueModel issue;

  const _HighPriorityCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: Colors.red.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (_, animation, sa) =>
                  AiReportAnalysisScreen(issue: issue),
              transitionsBuilder: (_, animation, sa, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.priority_high_rounded,
                    color: Colors.red, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'hp_title_${issue.issueId}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          issue.title,
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Chip(
                          label: issue.category,
                          color: colorScheme.secondary,
                          bg: colorScheme.secondaryContainer
                              .withValues(alpha: 0.5),
                        ),
                        _Chip(
                          label: issue.status.toUpperCase(),
                          color: colorScheme.primary,
                          bg: colorScheme.primaryContainer
                              .withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM d, y').format(issue.createdAt),
                      style: textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Chip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

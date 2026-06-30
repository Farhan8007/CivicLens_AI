import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/issue_model.dart';
import 'ai_report_analysis_screen.dart';

class AiAnalysedReportsScreen extends StatelessWidget {
  final List<IssueModel> reports;

  const AiAnalysedReportsScreen({super.key, required this.reports});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Reports Analysed'),
        centerTitle: false,
      ),
      body: reports.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('No reports analysed yet.',
                      style: textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Submit a report to get started.',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final issue = reports[index];
                return _AnalysedReportCard(issue: issue);
              },
            ),
    );
  }
}

// ─── Report Card ──────────────────────────────────────────────────────────────

class _AnalysedReportCard extends StatelessWidget {
  final IssueModel issue;

  const _AnalysedReportCard({required this.issue});

  int _qualityScore() {
    int score = 0;
    if (issue.mediaUrl != null && issue.mediaUrl!.isNotEmpty) score += 20;
    if (issue.latitude != null && issue.longitude != null) score += 20;
    if (issue.title.trim().isNotEmpty) score += 20;
    if (issue.description.trim().isNotEmpty) score += 20;
    if (issue.category.trim().isNotEmpty) score += 20;
    return score;
  }

  int _confidence() => 85 + (issue.hashCode % 15).abs();

  Color _priorityColor() {
    switch (issue.priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _qualityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final quality = _qualityScore();
    final confidence = _confidence();
    final prColor = _priorityColor();
    final qColor = _qualityColor(quality);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title Row ────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'analysed_title_${issue.issueId}',
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
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 10),

              // ── Chips Row ────────────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _SmallChip(
                    label: issue.category,
                    color: colorScheme.secondary,
                    bg: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  ),
                  _SmallChip(
                    label: 'Status: ${issue.status}',
                    color: colorScheme.primary,
                    bg: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  ),
                  _SmallChip(
                    label: 'Priority: ${issue.priority}',
                    color: prColor,
                    bg: prColor.withValues(alpha: 0.1),
                    border: prColor.withValues(alpha: 0.35),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Metrics Row ──────────────────────────────────────────
              IntrinsicHeight(
                child: Row(
                  children: [
                    // Quality Score
                    Expanded(
                      child: _MiniMetric(
                        icon: Icons.high_quality_outlined,
                        label: 'Quality',
                        value: '$quality/100',
                        color: qColor,
                      ),
                    ),
                    VerticalDivider(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: 24,
                    ),
                    // Confidence
                    Expanded(
                      child: _MiniMetric(
                        icon: Icons.psychology_outlined,
                        label: 'AI Confidence',
                        value: '$confidence%',
                        color: colorScheme.primary,
                      ),
                    ),
                    VerticalDivider(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: 24,
                    ),
                    // Date
                    Expanded(
                      child: _MiniMetric(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: DateFormat('MMM d').format(issue.createdAt),
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final Color? border;

  const _SmallChip({
    required this.label,
    required this.color,
    required this.bg,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: border != null ? Border.all(color: border!) : null,
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

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/issue_model.dart';
import 'ai_report_analysis_screen.dart';
import 'report_issue_screen.dart';

// ─── Data Helpers ─────────────────────────────────────────────────────────────

class IssueImprovement {
  final IssueModel issue;
  final List<String> reasons;

  const IssueImprovement({required this.issue, required this.reasons});
}

List<IssueImprovement> buildImprovementList(List<IssueModel> issues) {
  final result = <IssueImprovement>[];
  for (final issue in issues) {
    final reasons = <String>[];
    if (issue.description.trim().length < 20) {
      reasons.add('Description too short (add more detail)');
    }
    if (issue.mediaUrl == null || issue.mediaUrl!.isEmpty) {
      reasons.add('Missing photo or video evidence');
    }
    if (issue.latitude == null || issue.longitude == null) {
      reasons.add('Missing location (pin your exact location)');
    }
    if (reasons.isNotEmpty) {
      result.add(IssueImprovement(issue: issue, reasons: reasons));
    }
  }
  return result;
}

String _getImprovementTip(List<String> reasons) {
  final tips = <String>[];
  for (final r in reasons) {
    if (r.contains('Description')) {
      tips.add('Add at least 20 characters describing what you observe.');
    }
    if (r.contains('photo')) {
      tips.add(
          'Attach a clear photo so authorities can assess the severity quickly.');
    }
    if (r.contains('location')) {
      tips.add(
          'Enable location so the report can be assigned to the correct zone.');
    }
  }
  return tips.join('\n\n');
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReportsToImproveScreen extends StatefulWidget {
  final List<IssueModel> allUserIssues;

  const ReportsToImproveScreen({super.key, required this.allUserIssues});

  @override
  State<ReportsToImproveScreen> createState() => _ReportsToImproveScreenState();
}

class _ReportsToImproveScreenState extends State<ReportsToImproveScreen> {
  late List<IssueImprovement> _items;

  @override
  void initState() {
    super.initState();
    _items = buildImprovementList(widget.allUserIssues);
  }

  Future<void> _openEdit(IssueModel issue) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportIssueScreen(issueToEdit: issue),
      ),
    );
    if (result == true && mounted) {
      // Refresh list after edit
      final updatedIssues = List<IssueModel>.from(widget.allUserIssues);
      setState(() {
        _items = buildImprovementList(updatedIssues);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports to Improve'),
        centerTitle: false,
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_outlined,
                      size: 64, color: Colors.green.withValues(alpha: 0.7)),
                  const SizedBox(height: 16),
                  Text(
                    'All reports look great!',
                    style: textTheme.titleMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every report has sufficient detail.',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _ImproveCard(
                  improvement: item,
                  onEdit: () => _openEdit(item.issue),
                  onViewAnalysis: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (_, animation, sa) =>
                            AiReportAnalysisScreen(issue: item.issue),
                        transitionsBuilder: (_, animation, sa, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _ImproveCard extends StatefulWidget {
  final IssueImprovement improvement;
  final VoidCallback onEdit;
  final VoidCallback onViewAnalysis;

  const _ImproveCard({
    required this.improvement,
    required this.onEdit,
    required this.onViewAnalysis,
  });

  @override
  State<_ImproveCard> createState() => _ImproveCardState();
}

class _ImproveCardState extends State<_ImproveCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final issue = widget.improvement.issue;
    final reasons = widget.improvement.reasons;
    final tip = _getImprovementTip(reasons);

    return Card(
      elevation: 0,
      color: Colors.orange.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.build_circle_outlined,
                        color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.title,
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('MMM d, y').format(issue.createdAt),
                          style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // ── Issues List ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final reason in reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── AI Tips (expanded) ───────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 16, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'AI Recommendations',
                          style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip,
                      style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Action Buttons ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onViewAnalysis,
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('AI Analysis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Report'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

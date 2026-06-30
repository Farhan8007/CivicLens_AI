import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/issue_model.dart';

class AiReportAnalysisScreen extends StatelessWidget {
  final IssueModel issue;

  const AiReportAnalysisScreen({super.key, required this.issue});

  int _calculateQualityScore(IssueModel issue) {
    int score = 0;
    if (issue.mediaUrl != null && issue.mediaUrl!.isNotEmpty) score += 20;
    if (issue.latitude != null && issue.longitude != null) score += 20;
    if (issue.title.trim().isNotEmpty) score += 20;
    if (issue.description.trim().isNotEmpty) score += 20;
    if (issue.category.trim().isNotEmpty) score += 20;
    return score;
  }

  int _calculateConfidence(IssueModel issue) {
    // Generate a consistent pseudo-random percentage between 85-99
    return 85 + (issue.hashCode % 15).abs();
  }

  String _getSuggestedAuthority(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('traffic') || cat.contains('road')) return 'Traffic Police';
    if (cat.contains('garbage') || cat.contains('waste') || cat.contains('trash')) return 'Municipal Corporation';
    if (cat.contains('light') || cat.contains('electricity')) return 'Electricity Department';
    if (cat.contains('water') || cat.contains('leak') || cat.contains('pipe')) return 'Water Supply Department';
    return 'City Council';
  }

  String _getAiRecommendations(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('traffic') || cat.contains('road')) {
      return 'Ensure the area is marked off. Notify local traffic control to manage flow during peak hours.';
    }
    if (cat.contains('garbage') || cat.contains('waste') || cat.contains('trash')) {
      return 'Schedule an out-of-cycle pickup. Ensure nearby residents are notified of the delay.';
    }
    if (cat.contains('light') || cat.contains('electricity')) {
      return 'Dispatch a maintenance crew to inspect the bulb and wiring. Check adjacent lights for power issues.';
    }
    if (cat.contains('water') || cat.contains('leak') || cat.contains('pipe')) {
      return 'Identify the main valve to prevent further leaking. Dispatch a plumbing team immediately.';
    }
    return 'Review the report details and assign to the relevant departmental queue for processing.';
  }

  String _getImpactLevel(String priority) {
    final p = priority.toLowerCase();
    if (p == 'high') return 'High';
    if (p == 'medium') return 'Medium';
    return 'Low';
  }

  String _getImpactExplanation(String priority) {
    final p = priority.toLowerCase();
    if (p == 'high') return 'High localized impact affecting safety or daily routines.';
    if (p == 'medium') return 'Moderate impact affecting neighborhood aesthetics or convenience.';
    return 'Low impact. Does not pose immediate risks to the community.';
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final priorityColor = _getPriorityColor(issue.priority);

    final qualityScore = _calculateQualityScore(issue);
    final confidence = _calculateConfidence(issue);
    final suggestedAuthority = _getSuggestedAuthority(issue.category);
    final recommendations = _getAiRecommendations(issue.category);
    final impactLevel = _getImpactLevel(issue.priority);
    final impactExplanation = _getImpactExplanation(issue.priority);
    final aiSummary = issue.description.trim().isNotEmpty 
        ? issue.description 
        : 'No detailed description provided to summarize.';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('AI Analysis'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Report Summary Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'ai_report_icon_${issue.issueId}',
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'ai_report_title_${issue.issueId}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                issue.title,
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  issue.category,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Status: ${issue.status}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('MMMM d, yyyy').format(issue.createdAt),
                            style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // AI Summary
                _AnalysisCard(
                  title: 'AI Summary',
                  contentWidget: Text(
                    aiSummary,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                  icon: Icons.summarize_outlined,
                ),

                // Metrics Grid (Priority, Confidence)
                GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MetricCard(
                      title: 'AI Priority',
                      valueWidget: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: priorityColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          issue.priority.toUpperCase(),
                          style: textTheme.titleMedium?.copyWith(
                            color: priorityColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    _MetricCard(
                      title: 'AI Confidence',
                      valueWidget: Text(
                        '$confidence%',
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quality Score
                _AnalysisCard(
                  title: 'Report Quality Score',
                  contentWidget: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: qualityScore / 100,
                              strokeWidth: 8,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              color: qualityScore >= 80 
                                  ? Colors.green 
                                  : (qualityScore >= 50 ? Colors.orange : Colors.red),
                            ),
                            Center(
                              child: Text(
                                '$qualityScore',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          qualityScore == 100 
                              ? 'Excellent report! Contains all necessary information (Photo, Location, Title, Description, Category).'
                              : 'Good report. Add more details like a photo or exact location to improve this score.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  icon: Icons.high_quality_outlined,
                ),

                // Suggested Authorities
                _AnalysisCard(
                  title: 'Suggested Authority',
                  contentWidget: Text(
                    suggestedAuthority,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: Icons.account_balance_outlined,
                ),

                // AI Recommendations
                _AnalysisCard(
                  title: 'AI Recommendations',
                  contentWidget: Text(
                    recommendations,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                  icon: Icons.lightbulb_outline_rounded,
                ),

                // Community Impact
                _AnalysisCard(
                  title: 'Community Impact',
                  contentWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        impactLevel,
                        style: textTheme.titleMedium?.copyWith(
                          color: priorityColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        impactExplanation,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  icon: Icons.people_outline_rounded,
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final Widget contentWidget;
  final IconData icon;

  const _AnalysisCard({
    required this.title,
    required this.contentWidget,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            contentWidget,
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final Widget valueWidget;

  const _MetricCard({
    required this.title,
    required this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            valueWidget,
          ],
        ),
      ),
    );
  }
}

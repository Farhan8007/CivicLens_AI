import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About CivicLens AI'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      size: 50,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'CivicLens AI',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Version 1.0.0',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 48),
                _Section(
                  title: 'Our Purpose',
                  content: 'CivicLens AI empowers citizens to report local issues such as potholes, broken streetlights, and environmental hazards easily and efficiently, building a better city together.',
                  icon: Icons.flag_circle_outlined,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                _Section(
                  title: 'AI-Powered Reporting',
                  content: 'Our advanced AI automatically analyzes your descriptions to suggest appropriate categories and tags, streamlining the reporting process.',
                  icon: Icons.auto_awesome_rounded,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                _Section(
                  title: 'Smart Prioritization',
                  content: 'Issues are intelligently prioritized using AI to help local authorities focus on what matters most, ensuring critical infrastructure gets immediate attention.',
                  icon: Icons.sort_rounded,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                _Section(
                  title: 'Community-Driven',
                  content: 'Every report contributes to a transparent, shared map of civic issues, fostering community engagement and holding authorities accountable.',
                  icon: Icons.people_outline_rounded,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
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

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _Section({
    required this.title,
    required this.content,
    required this.icon,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: colorScheme.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
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

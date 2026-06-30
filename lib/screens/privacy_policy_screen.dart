import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Privacy Policy',
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last Updated: June 2026',
                  style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                _PolicySection(
                  title: '1. Data Collected',
                  content: 'We collect information you provide directly to us when reporting civic issues. This includes your display name, email address (for authentication), text descriptions of the issues, and any media (photos or videos) you choose to attach.',
                  textTheme: textTheme,
                ),
                _PolicySection(
                  title: '2. Location Usage',
                  content: 'CivicLens AI requires your precise location data when you submit a report. This location is tagged to the issue so that local authorities and other community members know exactly where the problem is. We do not track your location in the background.',
                  textTheme: textTheme,
                ),
                _PolicySection(
                  title: '3. Camera & Media Usage',
                  content: 'The app requests access to your camera and photo library strictly for the purpose of attaching media to your reports. Media files are securely uploaded to our cloud storage and linked to your public reports.',
                  textTheme: textTheme,
                ),
                _PolicySection(
                  title: '4. AI Processing',
                  content: 'To improve reporting efficiency, the text and images you submit may be processed by our AI services to automatically categorize and prioritize the issue. This data is not used to train generative AI models without explicit consent.',
                  textTheme: textTheme,
                ),
                _PolicySection(
                  title: '5. Data Security',
                  content: 'We implement industry-standard security measures, including encryption in transit and at rest, to protect your personal information and report data from unauthorized access.',
                  textTheme: textTheme,
                ),
                _PolicySection(
                  title: '6. User Rights',
                  content: 'You have the right to access, correct, or delete your personal data. You can edit your display name directly in the app. For full account deletion, please contact our support team.',
                  textTheme: textTheme,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'By using CivicLens AI, you consent to the practices described in this policy.',
                    style: textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  final TextTheme textTheme;

  const _PolicySection({
    required this.title,
    required this.content,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

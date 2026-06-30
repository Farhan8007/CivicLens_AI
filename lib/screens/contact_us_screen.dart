import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString, String errorMessage) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
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
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
                      size: 40,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'We\'re here to help!',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Text(
                  'Have feedback, questions, or need assistance? Don\'t hesitate to reach out to us using the details below.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(Icons.email_outlined, color: colorScheme.primary),
                          ),
                          title: Text(
                            'Email Us',
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text('farhanbagwan70@gmail.com'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _launchUrl(
                            context,
                            'mailto:farhanbagwan70@gmail.com?subject=CivicLens%20AI%20Support',
                            'Could not open email client.',
                          ),
                        ),
                        const Divider(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.tertiaryContainer,
                            child: Icon(Icons.phone_outlined, color: colorScheme.tertiary),
                          ),
                          title: Text(
                            'Call Us',
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text('+91 7774828407'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _launchUrl(
                            context,
                            'tel:+917774828407',
                            'Could not open dialer.',
                          ),
                        ),
                      ],
                    ),
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

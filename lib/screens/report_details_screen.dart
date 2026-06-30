import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/issue_model.dart';
import '../services/issue_service.dart';
import '../widgets/priority_chip.dart';
import '../widgets/report_status_chip.dart';
import '../widgets/shimmer_loading.dart';

class ReportDetailsScreen extends StatelessWidget {
  final IssueModel issue;
  final Future<void> Function(String issueId)? deleteIssue;

  const ReportDetailsScreen({super.key, required this.issue, this.deleteIssue});

  String get _formattedDate {
    final date = issue.createdAt.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year}, $hour:$minute';
  }

  String get _formattedLocation {
    if (issue.latitude == null || issue.longitude == null) {
      return 'Not provided';
    }
    return '${issue.latitude!.toStringAsFixed(6)}, '
        '${issue.longitude!.toStringAsFixed(6)}';
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Delete report?'),
          content: Text(
            'This will permanently delete "${issue.title}". '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(child: Text('Deleting report...')),
              ],
            ),
          ),
        );
      },
    );

    try {
      // TODO: Securely delete Cloudinary media through a trusted backend or
      // Firebase Cloud Function when issue.mediaUrl is present.
      await (deleteIssue ?? IssueService().deleteIssue)(issue.issueId);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete the report. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Report Details'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _confirmAndDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete report',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ── Media ──────────────────────────────────────────────────
              _ReportMedia(mediaUrl: issue.mediaUrl, mediaType: issue.mediaType),
              const SizedBox(height: 24),

              // ── Title ──────────────────────────────────────────────────
              Text(
                issue.title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // ── Status + Priority chips ────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ReportStatusChip(status: issue.status),
                  PriorityChip(priority: issue.priority),
                ],
              ),
              const SizedBox(height: 24),

              // ── Description ───────────────────────────────────────────
              _SectionCard(
                title: 'Description',
                icon: Icons.notes_rounded,
                child: Text(
                  issue.description.isEmpty
                      ? 'No description provided.'
                      : issue.description,
                  style: textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: 12),

              // ── Details card ──────────────────────────────────────────
              _SectionCard(
                title: 'Details',
                icon: Icons.info_outline_rounded,
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: issue.category,
                    ),
                    const _DetailDivider(),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date Reported',
                      value: _formattedDate,
                    ),
                    const _DetailDivider(),
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: _formattedLocation,
                    ),
                    const _DetailDivider(),
                    _DetailRow(
                      icon: Icons.fingerprint_rounded,
                      label: 'Report ID',
                      value: issue.issueId,
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

// ── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              SelectableText(
                value.isEmpty ? 'Not available' : value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Media Section ─────────────────────────────────────────────────────────────

class _ReportMedia extends StatefulWidget {
  final String? mediaUrl;
  final String? mediaType;

  const _ReportMedia({required this.mediaUrl, required this.mediaType});

  @override
  State<_ReportMedia> createState() => _ReportMediaState();
}

class _ReportMediaState extends State<_ReportMedia> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideo;

  bool get _isVideo =>
      widget.mediaType?.toLowerCase() == 'video' &&
      widget.mediaUrl?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.mediaUrl!),
      );
      _videoController = controller;
      _initializeVideo = controller.initialize();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = widget.mediaUrl;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: mediaUrl == null || mediaUrl.isEmpty
              ? _MediaPlaceholder(
                  icon: Icons.image_not_supported_outlined,
                  message: 'No media attached',
                  colorScheme: colorScheme,
                )
              : _isVideo
              ? FutureBuilder<void>(
                  future: _initializeVideo,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ShimmerLoading(
                        child: Container(
                          color: colorScheme.surfaceContainerHighest,
                        ),
                      );
                    }
                    if (snapshot.hasError ||
                        _videoController?.value.isInitialized != true) {
                      return _MediaPlaceholder(
                        icon: Icons.videocam_off_outlined,
                        message: 'Unable to load video',
                        colorScheme: colorScheme,
                      );
                    }

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _togglePlayback,
                          iconSize: 36,
                          icon: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                      ],
                    );
                  },
                )
              : Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return ShimmerLoading(
                      child: Container(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _MediaPlaceholder(
                      icon: Icons.broken_image_outlined,
                      message: 'Unable to load image',
                      colorScheme: colorScheme,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;
  final ColorScheme colorScheme;

  const _MediaPlaceholder({
    required this.icon,
    required this.message,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

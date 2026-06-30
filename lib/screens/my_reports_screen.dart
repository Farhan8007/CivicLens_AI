import 'package:flutter/material.dart';
import '../models/issue_model.dart';
import '../services/auth_service.dart';
import '../services/issue_service.dart';
import '../widgets/priority_chip.dart';
import '../widgets/report_status_chip.dart';
import 'report_details_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final IssueService _issueService = IssueService();
  Future<List<IssueModel>>? _userIssuesFuture;

  String _searchQuery = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _userIssuesFuture = _loadIssues();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<List<IssueModel>> _loadIssues() {
    final user = _authService.currentUser;
    if (user == null) {
      return Future.error(StateError('Please sign in to view your reports.'));
    }

    return _issueService.getUserIssues(user.uid);
  }

  Future<void> _refreshIssues() async {
    final refreshedIssues = _loadIssues();
    setState(() {
      _userIssuesFuture = refreshedIssues;
    });

    try {
      await refreshedIssues;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not refresh reports. Please try again.'),
          ),
        );
      }
    }
  }

  void _retryLoading() {
    setState(() {
      _userIssuesFuture = _loadIssues();
    });
  }

  String? _getThumbnailUrl(String? url, String? type) {
    if (url == null) return null;
    if (type == 'image') return url;
    if (type == 'video') {
      final lastDot = url.lastIndexOf('.');
      if (lastDot != -1) {
        return '${url.substring(0, lastDot)}.jpg';
      }
    }
    return null;
  }
  
  Widget _buildShimmerLoading() {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final double pulse = 0.5 - (_shimmerController.value - 0.5).abs();
            final double opacity = 0.3 + (pulse * 2.0 * 0.5);
            return Opacity(
              opacity: opacity,
              child: child,
            );
          },
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 20, width: double.infinity, color: colorScheme.surfaceContainerHighest),
                        const SizedBox(height: 8),
                        Container(height: 14, width: 100, color: colorScheme.surfaceContainerHighest),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(height: 14, width: 80, color: colorScheme.surfaceContainerHighest),
                            Container(
                              height: 24, 
                              width: 60, 
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest, 
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search reports...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
            ),
          ),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Pending', 'Resolved'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    showCheckmark: false,
                    backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const Divider(height: 1),
          
          // Reports List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshIssues,
              child: FutureBuilder<List<IssueModel>>(
                future: _userIssuesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                     return _buildShimmerLoading();
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Unable to load your reports.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    onPressed: _retryLoading,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Try again'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final allIssues = snapshot.data;
                  if (allIssues == null || allIssues.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_turned_in_outlined, size: 80, color: colorScheme.outlineVariant),
                                  const SizedBox(height: 16),
                                  Text(
                                    "You haven't reported any issues yet.",
                                    style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Apply filters and search
                  final filteredIssues = allIssues.where((issue) {
                    // Filter by status
                    if (_selectedFilter != 'All') {
                      final status = issue.status.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
                      if (_selectedFilter == 'Pending' && status != 'pending') {
                        return false;
                      }
                      if (_selectedFilter == 'Resolved' && status != 'resolved') {
                        return false;
                      }
                    }
                    
                    // Filter by search
                    if (_searchQuery.isNotEmpty) {
                      return issue.title.toLowerCase().contains(_searchQuery) ||
                             issue.description.toLowerCase().contains(_searchQuery) ||
                             issue.category.toLowerCase().contains(_searchQuery);
                    }
                    return true;
                  }).toList();

                  if (filteredIssues.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 64, color: colorScheme.outlineVariant),
                                const SizedBox(height: 16),
                                Text(
                                  "No reports match your filters.",
                                  style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _selectedFilter = 'All';
                                    });
                                  },
                                  child: const Text('Clear Filters'),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredIssues.length,
                    itemBuilder: (context, index) {
                      final issue = filteredIssues[index];
                      final thumbnailUrl = _getThumbnailUrl(issue.mediaUrl, issue.mediaType);
                      final formattedDate = '${issue.createdAt.day.toString().padLeft(2, '0')}/${issue.createdAt.month.toString().padLeft(2, '0')}/${issue.createdAt.year}';

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            final wasDeleted = await Navigator.of(context).push<bool>(
                              MaterialPageRoute<bool>(
                                builder: (context) => ReportDetailsScreen(issue: issue),
                              ),
                            );

                            if (wasDeleted == true && context.mounted) {
                              await _refreshIssues();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Report deleted successfully.')),
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    color: colorScheme.surfaceContainerHighest,
                                    child: thumbnailUrl != null
                                        ? Image.network(
                                            thumbnailUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                issue.mediaType == 'video' ? Icons.videocam : Icons.broken_image,
                                                color: colorScheme.onSurfaceVariant,
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.image_not_supported_outlined,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              issue.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ReportStatusChip(status: issue.status),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      Row(
                                        children: [
                                          Icon(Icons.category_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Text(
                                            issue.category,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            formattedDate,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          PriorityChip(priority: issue.priority),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

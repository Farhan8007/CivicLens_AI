import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import 'edit_profile_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'contact_us_screen.dart';
import 'ai_report_analysis_screen.dart';
import 'ai_analysed_reports_screen.dart';
import 'high_priority_reports_screen.dart';
import 'nearby_alerts_screen.dart';
import 'reports_to_improve_screen.dart';

import '../models/issue_model.dart';
import '../services/auth_service.dart';
import '../services/issue_service.dart';
import '../services/user_service.dart';

import 'map_screen.dart';
import 'my_reports_screen.dart';
import 'report_details_screen.dart';
import 'report_issue_screen.dart';
import '../widgets/civiclens_logo.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final IssueService _issueService = IssueService();

  String? _displayName;
  String? _email;
  String? _photoUrl;
  bool _isSigningOut = false;
  String? _errorMessage;

  late Future<List<IssueModel>> _issuesFuture;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _issuesFuture = _issueService.getAllIssues();
  }

  Future<void> _loadUserProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _email = user.email;
          _photoUrl = user.photoURL;
        });
      }
      try {
        final name = await _userService.getDisplayName();
        if (name != null && name.trim().isNotEmpty && mounted) {
          setState(() {
            _displayName = name;
          });
        }
      } catch (e) {
        debugPrint('Error loading user profile: $e');
      }
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isSigningOut = true;
      _errorMessage = null;
    });
    try {
      await _authService.signOut();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            displayName: _displayName,
            issuesFuture: _issuesFuture,
            onOpenAi: () => _onTabTapped(1),
            onOpenMyReports: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReportsScreen()));
            },
            onAddReport: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen()));
            },
          ),
          const _AiTab(),
          _ProfileTab(
            displayName: _displayName,
            email: _email,
            photoUrl: _photoUrl,
            isSigningOut: _isSigningOut,
            errorMessage: _errorMessage,
            onSignOut: _handleSignOut,
            onProfileUpdated: _loadUserProfile,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Home Tab ─────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final String? displayName;
  final Future<List<IssueModel>> issuesFuture;
  final VoidCallback onOpenAi;
  final VoidCallback onOpenMyReports;
  final VoidCallback onAddReport;

  const _HomeTab({
    required this.displayName,
    required this.issuesFuture,
    required this.onOpenAi,
    required this.onOpenMyReports,
    required this.onAddReport,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leadingWidth: 62,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16, top: 6, bottom: 6),
          child: CivicLensLogo(size: 40),
        ),
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _greeting(),
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              displayName ?? 'CivicLens user',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Report an issue',
            onPressed: onAddReport,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FutureBuilder<List<IssueModel>>(
            future: issuesFuture,
            builder: (context, snapshot) {
              final issues = snapshot.data ?? const <IssueModel>[];
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData;
              final recentReports = issues.take(5).toList();

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ListView(
                  key: ValueKey(
                    isLoading
                        ? 'loading'
                        : (snapshot.hasError ? 'error' : 'data'),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: <Widget>[
                    Text(
                      "Let's improve our city together.",
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (snapshot.hasError)
                      _ErrorCard(message: 'Unable to load report statistics. Please check your connection and try again.')
                    else if (isLoading)
                      const _StatsGridSkeleton()
                    else
                      _StatsGrid(issues: issues),
                    const SizedBox(height: 24),
                    Text(
                      'Quick Actions',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.add_location_alt_outlined,
                            title: 'New Report',
                            color: Colors.blue,
                            onTap: onAddReport,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.map_outlined,
                            title: 'View Map',
                            color: Colors.green,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.auto_awesome_outlined,
                            title: 'AI Insights',
                            color: Colors.purple,
                            onTap: onOpenAi,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Reports',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextButton(
                          onPressed: onOpenMyReports,
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (isLoading)
                      const CircularProgressIndicator()
                    else if (recentReports.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No reports yet.')))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentReports.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final issue = recentReports[index];
                          return Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ReportDetailsScreen(issue: issue)),
                                );
                              },
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.report_outlined, color: colorScheme.onPrimaryContainer),
                              ),
                              title: Text(issue.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(issue.category, maxLines: 1),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<IssueModel> issues;

  const _StatsGrid({required this.issues});

  @override
  Widget build(BuildContext context) {
    int pending = 0;
    int resolved = 0;
    for (var issue in issues) {
      if (issue.status.toLowerCase() == 'resolved') {
        resolved++;
      } else {
        pending++;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Reports',
            count: issues.length.toString(),
            icon: Icons.library_books_outlined,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Resolved',
            count: resolved.toString(),
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Pending',
            count: pending.toString(),
            icon: Icons.pending_actions_outlined,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: SizedBox(height: 100, child: Card())),
        SizedBox(width: 12),
        Expanded(child: SizedBox(height: 100, child: Card())),
        SizedBox(width: 12),
        Expanded(child: SizedBox(height: 100, child: Card())),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(count, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
          Text(title, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── AI Tab ─────────────────────────────────────────────────────────────────

class _AiDashboardData {
  final List<IssueModel> userIssues;
  final int highPriorityCount;
  final int reportsToImproveCount;
  final List<Map<String, dynamic>> nearbyReports;

  _AiDashboardData({
    required this.userIssues,
    required this.highPriorityCount,
    required this.reportsToImproveCount,
    required this.nearbyReports,
  });
}

class _AiTab extends StatefulWidget {
  const _AiTab();

  @override
  State<_AiTab> createState() => _AiTabState();
}

class _AiTabState extends State<_AiTab> {
  final AuthService _authService = AuthService();
  final IssueService _issueService = IssueService();
  late Future<_AiDashboardData> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _fetchDashboardData();
  }

  Future<_AiDashboardData> _fetchDashboardData() async {
    final user = _authService.currentUser;
    if (user == null) {
      return _AiDashboardData(userIssues: [], highPriorityCount: 0, reportsToImproveCount: 0, nearbyReports: []);
    }

    final userIssues = await _issueService.getUserIssues(user.uid);

    int highPriority = 0;
    int toImprove = 0;
    for (var issue in userIssues) {
      if (issue.priority.toLowerCase() == 'high') highPriority++;
      
      if (issue.description.length < 20 ||
          (issue.mediaUrl == null || issue.mediaUrl!.isEmpty) ||
          (issue.latitude == null || issue.longitude == null)) {
        toImprove++;
      }
    }

    List<Map<String, dynamic>> nearbyList = [];
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition();
          final allIssues = await _issueService.getAllIssues();

          for (var issue in allIssues) {
            if (issue.latitude != null && issue.longitude != null) {
              final distance = Geolocator.distanceBetween(
                  position.latitude, position.longitude, issue.latitude!, issue.longitude!);
              if (distance <= 5000) {
                nearbyList.add({
                  'issue': issue,
                  'distance': distance,
                });
              }
            }
          }
          nearbyList.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
        }
      }
    } catch (e) {
      debugPrint('Error calculating nearby alerts: $e');
    }

    return _AiDashboardData(
      userIssues: userIssues,
      highPriorityCount: highPriority,
      reportsToImproveCount: toImprove,
      nearbyReports: nearbyList,
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low':
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _dashboardDataFuture = _fetchDashboardData();
                });
              },
              child: FutureBuilder<_AiDashboardData>(
                future: _dashboardDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading AI Dashboard', style: TextStyle(color: colorScheme.error)));
                  }

                  final data = snapshot.data!;
                  final issues = data.userIssues;

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Header
                      Text(
                        'CivicLens AI',
                        style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your Intelligent Civic Assistant',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // AI Overview Card
                      Card(
                        elevation: 0,
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: colorScheme.primary, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('How AI Helps You', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'CivicLens AI automatically analyzes your reports, determines their priority, evaluates report quality, provides intelligent recommendations, and identifies nearby civic issues to keep your community safe.',
                                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // AI Insights Section
                      GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.1,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // ── Nearby Alerts ──────────────────────────
                          _TappableInsightCard(
                            title: 'Nearby Alerts',
                            count: '${data.nearbyReports.length}',
                            icon: Icons.notifications_active_outlined,
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NearbyAlertsScreen(
                                    nearbyReports: data.nearbyReports),
                              ),
                            ),
                          ),
                          // ── High Priority ──────────────────────────
                          _TappableInsightCard(
                            title: 'High Priority Reports',
                            count: '${data.highPriorityCount}',
                            icon: Icons.priority_high_rounded,
                            color: Colors.red,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HighPriorityReportsScreen(
                                    reports: issues),
                              ),
                            ),
                          ),
                          // ── Reports to Improve ─────────────────────
                          _TappableInsightCard(
                            title: 'Reports to Improve',
                            count: '${data.reportsToImproveCount}',
                            icon: Icons.build_circle_outlined,
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportsToImproveScreen(
                                    allUserIssues: issues),
                              ),
                            ),
                          ),
                          // ── AI Reports Analysed ────────────────────
                          _TappableInsightCard(
                            title: 'AI Reports Analysed',
                            count: '${issues.length}',
                            icon: Icons.analytics_outlined,
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AiAnalysedReportsScreen(reports: issues),
                              ),
                            ),
                          ),
                        ],

                      ),
                      const SizedBox(height: 32),

                      // Analyze My Reports Section
                      Text(
                        'Analyze My Reports',
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),

                      if (issues.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('No reports found to analyze.'),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: issues.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final issue = issues[index];
                            final priorityColor = _getPriorityColor(issue.priority);

                            return Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                                      pageBuilder: (context, animation, secondaryAnimation) => AiReportAnalysisScreen(issue: issue),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(opacity: animation, child: child);
                                      },
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
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
                                                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
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
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: priorityColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: priorityColor.withValues(alpha: 0.5)),
                                                  ),
                                                  child: Text(
                                                    'AI: ${issue.priority}',
                                                    style: textTheme.labelSmall?.copyWith(
                                                      color: priorityColor,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              DateFormat('MMM d, y').format(issue.createdAt),
                                              style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Hero(
                                        tag: 'ai_report_icon_${issue.issueId}',
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            color: colorScheme.onPrimaryContainer,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// Tappable insight card with ripple + arrow hint
class _TappableInsightCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TappableInsightCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    count,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _ProfileTab extends StatelessWidget {
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool isSigningOut;
  final String? errorMessage;
  final VoidCallback onSignOut;
  final VoidCallback onProfileUpdated;

  const _ProfileTab({
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.isSigningOut,
    required this.errorMessage,
    required this.onSignOut,
    required this.onProfileUpdated,
  });

  Future<void> _openEditProfile(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (result == true) {
      onProfileUpdated();
    }
  }

  void _openAbout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  void _openContactUs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactUsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final resolvedName =
        (displayName != null && displayName!.trim().isNotEmpty)
            ? displayName!
            : 'CivicLens user';
    final resolvedEmail =
        (email != null && email!.trim().isNotEmpty)
            ? email!
            : 'No email available';
    final hasPhoto = photoUrl?.trim().isNotEmpty == true;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: <Widget>[
              // ── Avatar + name card ───────────────────────────────────
              Card(
                elevation: 0,
                color: colorScheme.primaryContainer.withValues(alpha: 0.34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: colorScheme.primary,
                        foregroundImage:
                            hasPhoto ? NetworkImage(photoUrl!) : null,
                        child: hasPhoto
                            ? null
                            : Text(
                                resolvedName.characters.first.toUpperCase(),
                                style: textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                resolvedName,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              resolvedEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => _openEditProfile(context),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit profile',
                      ),
                    ],
                  ),
                ),
              ),

              if (errorMessage != null) ...<Widget>[
                const SizedBox(height: 12),
                _ErrorCard(message: errorMessage!),
              ],

              const SizedBox(height: 20),
              Text(
                'Menu',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),

              // ── Menu card ────────────────────────────────────────────
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: <Widget>[
                    _MenuTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile',
                      onTap: () => _openEditProfile(context),
                    ),
                    _MenuDivider(),
                    _MenuTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About CivicLens AI',
                      onTap: () => _openAbout(context),
                    ),
                    _MenuDivider(),
                    _MenuTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () => _openPrivacyPolicy(context),
                    ),
                    _MenuDivider(),
                    _MenuTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Contact Us',
                      onTap: () => _openContactUs(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Logout ───────────────────────────────────────────────
              Card(
                elevation: 0,
                color: colorScheme.errorContainer.withValues(alpha: 0.45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: colorScheme.error.withValues(alpha: 0.12),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Icon(Icons.logout_rounded, color: colorScheme.error),
                  title: Text(
                    isSigningOut ? 'Signing out...' : 'Logout',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  trailing: isSigningOut
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: colorScheme.error,
                          ),
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.error,
                        ),
                  onTap: isSigningOut ? null : onSignOut,
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}


// ── Menu Tile & Divider ───────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 21),
      ),
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: Theme.of(context)
            .colorScheme
            .outlineVariant
            .withValues(alpha: 0.5),
      ),
    );
  }
}

// ── Error Card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline_rounded,
                color: colorScheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

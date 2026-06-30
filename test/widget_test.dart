import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civiclens_ai/main.dart';
import 'package:civiclens_ai/models/issue_model.dart';
import 'package:civiclens_ai/screens/home_screen.dart';
import 'package:civiclens_ai/screens/login_screen.dart';
import 'package:civiclens_ai/screens/map_screen.dart';
import 'package:civiclens_ai/screens/report_details_screen.dart';
import 'package:civiclens_ai/screens/signup_screen.dart';
import 'package:civiclens_ai/widgets/report_status_chip.dart';

void main() {
  test('authentication widgets are available', () {
    expect(const CivicLensApp(), isA<CivicLensApp>());
    expect(const AuthGate(), isA<AuthGate>());
    expect(const LoginScreen(), isA<LoginScreen>());
    expect(const SignupScreen(), isA<SignupScreen>());
    expect(const HomeScreen(), isA<HomeScreen>());
  });

  testWidgets('report details show read-only issue data', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final issue = IssueModel(
      issueId: 'report-123',
      userId: 'user-1',
      userEmail: 'user@example.com',
      title: 'Broken streetlight',
      description: 'The streetlight has not worked for two nights.',
      category: 'Infrastructure',
      status: 'in_progress',
      priority: 'Medium',
      createdAt: DateTime(2026, 6, 29, 18, 30),
      latitude: 19.076,
      longitude: 72.8777,
    );

    await tester.pumpWidget(
      MaterialApp(home: ReportDetailsScreen(issue: issue)),
    );

    expect(find.text('Broken streetlight'), findsOneWidget);
    expect(
      find.text('The streetlight has not worked for two nights.'),
      findsOneWidget,
    );
    expect(find.text('Infrastructure'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('29/06/2026, 18:30'), findsOneWidget);
    expect(find.text('19.076000, 72.877700'), findsOneWidget);
    expect(find.text('report-123'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('report deletion asks for confirmation and can be cancelled', (
    tester,
  ) async {
    var deleteCalled = false;
    final issue = IssueModel(
      issueId: 'report-to-delete',
      userId: 'user-1',
      userEmail: 'user@example.com',
      title: 'Overflowing bin',
      description: 'The bin is overflowing.',
      category: 'Sanitation',
      status: 'pending',
      priority: 'Medium',
      createdAt: DateTime(2026, 6, 29),
      mediaUrl: 'https://example.com/media.jpg',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ReportDetailsScreen(
          issue: issue,
          deleteIssue: (_) async {
            deleteCalled = true;
          },
        ),
      ),
    );

    await tester.tap(find.byTooltip('Delete report'));
    await tester.pumpAndSettle();

    expect(find.text('Delete report?'), findsOneWidget);
    expect(
      find.textContaining('This action cannot be undone.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(deleteCalled, isFalse);
    expect(find.text('Delete report?'), findsNothing);
    expect(find.text('Overflowing bin'), findsOneWidget);
  });

  testWidgets('report status chips show all supported labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              ReportStatusChip(status: 'pending'),
              ReportStatusChip(status: 'in_review'),
              ReportStatusChip(status: 'in progress'),
              ReportStatusChip(status: 'resolved'),
              ReportStatusChip(status: 'rejected'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('In Review'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.byType(Chip), findsNWidgets(5));
  });

  test('issue map creates one marker per valid issue location', () {
    final locatedIssue = IssueModel(
      issueId: 'issue-1',
      userId: 'user-1',
      userEmail: 'user@example.com',
      title: 'Pothole',
      description: 'Large pothole near the junction.',
      category: 'Infrastructure',
      status: 'in_review',
      priority: 'Medium',
      createdAt: DateTime(2026, 6, 29),
      latitude: 19.076,
      longitude: 72.8777,
    );
    final issueWithoutLocation = IssueModel(
      issueId: 'issue-2',
      userId: 'user-1',
      userEmail: 'user@example.com',
      title: 'Broken light',
      description: 'Streetlight is not working.',
      category: 'Safety',
      status: 'pending',
      priority: 'Medium',
      createdAt: DateTime(2026, 6, 29),
    );

    final markers = createIssueMarkers([locatedIssue, issueWithoutLocation]);

    expect(markers, hasLength(1));
    expect(markers.single.markerId.value, 'issue-1');
    expect(markers.single.infoWindow.title, 'Pothole');
    expect(markers.single.infoWindow.snippet, 'Infrastructure • In Review');
  });
}

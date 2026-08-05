import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_util/presentation/widgets/pr_status_badge.dart';

void main() {
  testWidgets('PRStatusBadge renders Open state correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PRStatusBadge(state: 'open'),
        ),
      ),
    );

    expect(find.text('Open'), findsOneWidget);
    expect(find.byIcon(Icons.call_merge_rounded), findsOneWidget);
  });

  testWidgets('PRStatusBadge renders Draft state correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PRStatusBadge(state: 'open', isDraft: true),
        ),
      ),
    );

    expect(find.text('Draft'), findsOneWidget);
    expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:marquis/app.dart';
import 'package:marquis/core/constants.dart';

void main() {
  testWidgets('App launches and shows app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MarquisApp()),
    );
    await tester.pumpAndSettle();

    // The app name appears in the content area placeholder
    expect(find.text(AppConstants.appName), findsOneWidget);
  });

  testWidgets('App shows toolbar and status bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MarquisApp()),
    );
    await tester.pumpAndSettle();

    // Status bar shows encoding and format
    expect(find.text('UTF-8'), findsOneWidget);
    expect(find.text('Markdown'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
  });
}

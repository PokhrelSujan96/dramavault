import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const names = [
    'home_outline',
    'home_fill',
    'discover_outline',
    'discover_fill',
    'bookmark_outline',
    'bookmark_fill',
    'profile_outline',
    'profile_fill',
    'episodes',
    'heart',
    'comment',
    'share',
    'play',
  ];

  for (final name in names) {
    testWidgets('$name.svg parses and renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(child: FlareSvgIcon(name, size: 24, color: Colors.red)),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(FlareSvgIcon), findsOneWidget);
    });
  }
}

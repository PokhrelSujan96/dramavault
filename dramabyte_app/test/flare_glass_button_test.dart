import 'package:dramabyte_app/components/flare_glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('glass button renders over an image and handles taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: Stack(
              alignment: Alignment.center,
              children: [
                const ColoredBox(color: Colors.deepPurple),
                FlareGlassButton(
                  label: 'Play Now',
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => taps++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
    await tester.tap(find.text('Play Now'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}

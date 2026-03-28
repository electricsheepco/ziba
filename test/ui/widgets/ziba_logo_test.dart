import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziba/ui/widgets/ziba_logo.dart';

void main() {
  testWidgets('dark variant renders ZIBA text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ZibaLogo())),
    );
    expect(find.text('ZIBA'), findsOneWidget);
  });

  testWidgets('light variant renders ZIBA text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ZibaLogo(variant: ZibaLogoVariant.light),
        ),
      ),
    );
    expect(find.text('ZIBA'), findsOneWidget);
  });

  testWidgets('markOnly variant has no ZIBA text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ZibaLogo(variant: ZibaLogoVariant.markOnly),
        ),
      ),
    );
    expect(find.text('ZIBA'), findsNothing);
  });

  testWidgets('dark variant renders without exceptions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ZibaLogo(size: 40))),
    );
    expect(tester.takeException(), isNull);
  });
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ziba/main.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('bodyLarge has smcp font feature', (tester) async {
    final app = ZibaApp();
    final theme = app.buildTheme(Brightness.dark);
    await tester.pump();
    final features = theme.textTheme.bodyLarge?.fontFeatures;
    expect(features, contains(const FontFeature('smcp')));
  });

  testWidgets('labelSmall has smcp font feature', (tester) async {
    final app = ZibaApp();
    final theme = app.buildTheme(Brightness.dark);
    await tester.pump();
    final features = theme.textTheme.labelSmall?.fontFeatures;
    expect(features, contains(const FontFeature('smcp')));
  });
}

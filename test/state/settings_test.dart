import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ziba/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AppSettings defaults are correct', () {
    const s = AppSettings();
    expect(s.autoRotate, isTrue);
    expect(s.rotationInterval, const Duration(hours: 24));
    expect(s.preferLandscape, isTrue);
    expect(s.artMovementFilter, isEmpty);
    expect(s.launchAtLogin, isFalse);
    expect(s.themeMode, ThemeMode.dark);
  });

  test('AppSettings.copyWith preserves unset fields', () {
    const s = AppSettings(autoRotate: false);
    final s2 = s.copyWith(preferLandscape: false);
    expect(s2.autoRotate, isFalse);
    expect(s2.preferLandscape, isFalse);
    expect(s2.rotationInterval, const Duration(hours: 24));
  });

  test('rotationInterval copyWith', () {
    const s = AppSettings();
    final s2 = s.copyWith(rotationInterval: const Duration(hours: 6));
    expect(s2.rotationInterval, const Duration(hours: 6));
    expect(s2.autoRotate, isTrue); // unchanged
  });

  test('AppSettings.copyWith preserves themeMode', () {
    const s = AppSettings(themeMode: ThemeMode.light);
    final s2 = s.copyWith(autoRotate: false);
    expect(s2.themeMode, ThemeMode.light);  // preserved
    expect(s2.autoRotate, isFalse);          // changed
  });
}

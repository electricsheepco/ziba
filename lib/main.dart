import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ZibaApp()));
}

class ZibaApp extends StatelessWidget {
  const ZibaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ziba',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: _buildTheme(Brightness.dark),
      theme: _buildTheme(Brightness.light),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A1A2E),
        brightness: brightness,
        surface: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5F0),
        onSurface: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
      ),
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5F0),
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
        bodyLarge: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF444444),
        ),
        bodyMedium: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 2,
          color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF5F5F0),
        indicatorColor: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

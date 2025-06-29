import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:genews/features/settings/providers/settings_provider.dart';
import 'package:genews/features/main/views/main_screen.dart';
import 'package:genews/app/themes/colors.dart';

class GeNewsApp extends StatelessWidget {
  const GeNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return MaterialApp(
      title: 'GeNews',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,

      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          primary: AppColors.primaryColor,
          seedColor: Colors.black,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1.0,
          scrolledUnderElevation: 2.0,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: _buildTextTheme(
          ThemeData.light().textTheme,
          fontSizeProvider.fontSizeMultiplier,
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black54),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black54),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
            side: const BorderSide(color: Colors.black38),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50.0),
              side: const BorderSide(color: Colors.black54),
            ),
          ),
        ),
        useMaterial3: true,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          primary: AppColors.primaryColor,
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        textTheme: _buildTextTheme(
          ThemeData.dark().textTheme,
          fontSizeProvider.fontSizeMultiplier,
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white70),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50.0),
            side: const BorderSide(color: Colors.white70),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50.0),
              side: const BorderSide(color: Colors.white70),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const MainScreen(),
      ),
    );
  }

  TextTheme _buildTextTheme(TextTheme base, double fontSizeMultiplier) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontSize: (base.displayLarge?.fontSize ?? 57) * fontSizeMultiplier,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontSize: (base.displayMedium?.fontSize ?? 45) * fontSizeMultiplier,
          ),
          displaySmall: base.displaySmall?.copyWith(
            fontSize: (base.displaySmall?.fontSize ?? 36) * fontSizeMultiplier,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontSize: (base.headlineLarge?.fontSize ?? 32) * fontSizeMultiplier,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontSize:
                (base.headlineMedium?.fontSize ?? 28) * fontSizeMultiplier,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: (base.headlineSmall?.fontSize ?? 24) * fontSizeMultiplier,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: (base.titleLarge?.fontSize ?? 22) * fontSizeMultiplier,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: (base.titleMedium?.fontSize ?? 16) * fontSizeMultiplier,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: (base.titleSmall?.fontSize ?? 14) * fontSizeMultiplier,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: (base.bodyLarge?.fontSize ?? 16) * fontSizeMultiplier,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: (base.bodyMedium?.fontSize ?? 14) * fontSizeMultiplier,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: (base.bodySmall?.fontSize ?? 12) * fontSizeMultiplier,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: (base.labelLarge?.fontSize ?? 14) * fontSizeMultiplier,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: (base.labelMedium?.fontSize ?? 12) * fontSizeMultiplier,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: (base.labelSmall?.fontSize ?? 11) * fontSizeMultiplier,
          ),
        )
        .apply(fontSizeFactor: fontSizeMultiplier);
  }
}

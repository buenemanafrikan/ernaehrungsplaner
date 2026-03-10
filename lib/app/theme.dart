import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';

ThemeData buildAppTheme(BuildContext context) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedGreen,
    brightness: Brightness.light,
  );

  final baseTextTheme = GoogleFonts.latoTextTheme(
    Theme.of(context).textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: scheme.primary);
        }
        return IconThemeData(color: scheme.onSurfaceVariant);
      }),
    ),

    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),

    appBarTheme: AppBarTheme(
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      titleTextStyle: GoogleFonts.lato(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),

    cardTheme: CardThemeData(
      color: const Color.fromARGB(255, 245, 248, 245),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: kCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: GoogleFonts.lato(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
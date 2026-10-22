import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ozouma brand colours.
class OzColors {
  static const linen = Color(0xFFFBF8F3);
  static const linenDeep = Color(0xFFF4EFE7);
  static const sand = Color(0xFFE9E1D5);
  static const ink = Color(0xFF1C1A17);
  static const inkSoft = Color(0xFF6B645B);
  static const line = Color(0xFFE7DFD3);
  static const plum = Color(0xFF5B2A4A);
  static const plumTint = Color(0xFFEFE6EC);
  static const saffron = Color(0xFFD99A1E);
  static const saffronSoft = Color(0xFFF1E4C7);
  static const alert = Color(0xFFB23A2E);
  static const listening = Color(0xFF2E7D5B);
}

class OzTheme {
  /// [remoteFonts] is false in tests so no font download is attempted.
  static ThemeData build({required bool arabic, bool remoteFonts = true}) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: OzColors.plum,
        primary: OzColors.plum,
        secondary: OzColors.saffron,
        surface: OzColors.linen,
        error: OzColors.alert,
      ),
      scaffoldBackgroundColor: OzColors.linenDeep,
    );

    TextTheme text = base.textTheme.apply(
      bodyColor: OzColors.ink,
      displayColor: OzColors.ink,
    );
    if (remoteFonts) {
      final body = arabic ? GoogleFonts.readexProTextTheme(text) : GoogleFonts.dmSansTextTheme(text);
      final display = arabic ? GoogleFonts.amiri(fontWeight: FontWeight.w700) : GoogleFonts.dmSerifDisplay();
      text = body.copyWith(
        displayLarge: display.merge(body.displayLarge),
        displayMedium: display.merge(body.displayMedium),
        displaySmall: display.merge(body.displaySmall),
        headlineLarge: display.merge(body.headlineLarge),
        headlineMedium: display.merge(body.headlineMedium),
        headlineSmall: display.merge(body.headlineSmall),
      );
    }

    return base.copyWith(
      textTheme: text,
      appBarTheme: const AppBarTheme(
        backgroundColor: OzColors.linenDeep,
        foregroundColor: OzColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: OzColors.plum,
          foregroundColor: OzColors.linen,
          minimumSize: const Size(48, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OzColors.ink,
          minimumSize: const Size(48, 52),
          shape: const StadiumBorder(),
          side: const BorderSide(color: OzColors.line, width: 1.2),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: OzColors.linen,
        selectedColor: OzColors.plum,
        side: const BorderSide(color: OzColors.line),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(color: OzColors.ink, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: OzColors.linen),
        checkmarkColor: OzColors.linen,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: OzColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: OzColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: OzColors.plum, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: OzColors.linen,
        indicatorColor: OzColors.plumTint,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? OzColors.plum : OzColors.inkSoft,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? OzColors.plum : OzColors.inkSoft,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: OzColors.linen,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: OzColors.ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

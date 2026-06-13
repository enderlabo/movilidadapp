import 'package:flutter/material.dart';

/// Sistema de diseño: glassmorphism moderno, paleta azul/blanco.
/// Minimalista — sin decoración innecesaria.
abstract final class AppTheme {
  // ─── Colores base ─────────────────────────────────────────────────────────
  static const Color azulPrimario = Color(0xFF1A5FBF);
  static const Color azulSecundario = Color(0xFF2D7DD2);
  static const Color azulClaro = Color(0xFFE8F1FB);
  static const Color azulMedium = Color(0xFF5B9BD5);
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color grisClaro = Color(0xFFF5F7FA);
  static const Color grisMedium = Color(0xFFB0BEC5);
  static const Color grisDark = Color(0xFF546E7A);
  static const Color textoPrimario = Color(0xFF1A2332);
  static const Color textoSecundario = Color(0xFF546E7A);
  static const Color error = Color(0xFFD32F2F);
  static const Color exito = Color(0xFF2E7D32);

  // ─── Glassmorphism ────────────────────────────────────────────────────────
  static const Color glassBackground = Color(0xCCFFFFFF);       // blanco 80%
  static const Color glassBorder = Color(0x4D1A5FBF);           // azul 30%
  static const Color glassShadow = Color(0x1A1A5FBF);           // azul 10%
  static const Color glassBackgroundDark = Color(0xCC0D1B2A);   // dark 80%
  static const Color glassBorderDark = Color(0x4D5B9BD5);

  // ─── Bordes ───────────────────────────────────────────────────────────────
  static const double borderRadius = 16.0;
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusLg = 24.0;

  // ─── Espaciado ────────────────────────────────────────────────────────────
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ─── Tema Light ───────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: azulPrimario,
          brightness: Brightness.light,
          primary: azulPrimario,
          secondary: azulSecundario,
          surface: grisClaro,
          error: error,
        ),
        scaffoldBackgroundColor: grisClaro,
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textoPrimario,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: azulPrimario),
        ),
        cardTheme: CardThemeData(
          color: glassBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: const BorderSide(color: glassBorder, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: azulPrimario,
            foregroundColor: blanco,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
                horizontal: spacingLg, vertical: spacingMd),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusSm),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: glassBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: azulPrimario, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: spacingMd, vertical: spacingMd),
          hintStyle: const TextStyle(color: grisMedium),
        ),
      );

  // ─── Tema Dark ────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: azulSecundario,
          brightness: Brightness.dark,
          primary: azulSecundario,
          secondary: azulMedium,
          surface: const Color(0xFF0D1B2A),
          error: const Color(0xFFEF9A9A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: blanco,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: azulMedium),
        ),
        cardTheme: CardThemeData(
          color: glassBackgroundDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: const BorderSide(color: glassBorderDark, width: 1),
          ),
        ),
      );
}

/// Widget reutilizable para el efecto glass.
/// DRY: un único lugar donde se define el glassmorphism.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.glassBackgroundDark : AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: isDark ? AppTheme.glassBorderDark : AppTheme.glassBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.glassShadow,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
            child: child,
          ),
        ),
      ),
    );
  }
}

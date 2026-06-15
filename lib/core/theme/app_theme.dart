import 'package:flutter/material.dart';

// ─── Paleta dinámica por tema ─────────────────────────────────────────────────

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.textoPrimario,
    required this.textoSecundario,
    required this.textoMuted,
    required this.superficieBase,
    required this.superficieCard,
    required this.superficieMid,
    required this.bordeInactivo,
    required this.naranjaTenue,
    required this.naranjaGlow,
  });

  final Color textoPrimario;
  final Color textoSecundario;
  final Color textoMuted;
  final Color superficieBase;
  final Color superficieCard;
  final Color superficieMid;
  final Color bordeInactivo;
  final Color naranjaTenue;
  final Color naranjaGlow;

  static const AppColors dark = AppColors(
    textoPrimario:   Color(0xFFFFFFFF),
    textoSecundario: Color(0xFF8CB4D6),
    textoMuted:      Color(0xFF3C5878),
    superficieBase:  Color(0xFF0E1D34),
    superficieCard:  Color(0xFF152740),
    superficieMid:   Color(0xFF1C3254),
    bordeInactivo:   Color(0x50F06428),
    naranjaTenue:    Color(0xFF2C1508),
    naranjaGlow:     Color(0x44F06428),
  );

  static const AppColors light = AppColors(
    textoPrimario:   Color(0xFF091628),  // navy profundo → texto primario
    textoSecundario: Color(0xFF1C3254),  // navy medio → texto secundario
    textoMuted:      Color(0xFF557898),  // navy gris → texto muted
    superficieBase:  Color(0xFFFFFFFF),  // blanco → fondo scaffold
    superficieCard:  Color(0xFFF0F5FC),  // azul muy claro → cards
    superficieMid:   Color(0xFFE2EEF8),  // azul claro → inputs
    bordeInactivo:   Color(0x80F06428),  // naranja 50% → bordes
    naranjaTenue:    Color(0xFFFFF0E8),  // naranja muy claro → fondos badge
    naranjaGlow:     Color(0x1AF06428),  // glow sutil sobre blanco
  );

  @override
  AppColors copyWith({
    Color? textoPrimario,
    Color? textoSecundario,
    Color? textoMuted,
    Color? superficieBase,
    Color? superficieCard,
    Color? superficieMid,
    Color? bordeInactivo,
    Color? naranjaTenue,
    Color? naranjaGlow,
  }) =>
      AppColors(
        textoPrimario:   textoPrimario   ?? this.textoPrimario,
        textoSecundario: textoSecundario ?? this.textoSecundario,
        textoMuted:      textoMuted      ?? this.textoMuted,
        superficieBase:  superficieBase  ?? this.superficieBase,
        superficieCard:  superficieCard  ?? this.superficieCard,
        superficieMid:   superficieMid   ?? this.superficieMid,
        bordeInactivo:   bordeInactivo   ?? this.bordeInactivo,
        naranjaTenue:    naranjaTenue    ?? this.naranjaTenue,
        naranjaGlow:     naranjaGlow     ?? this.naranjaGlow,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      textoPrimario:   Color.lerp(textoPrimario,   other.textoPrimario,   t)!,
      textoSecundario: Color.lerp(textoSecundario, other.textoSecundario, t)!,
      textoMuted:      Color.lerp(textoMuted,      other.textoMuted,      t)!,
      superficieBase:  Color.lerp(superficieBase,  other.superficieBase,  t)!,
      superficieCard:  Color.lerp(superficieCard,  other.superficieCard,  t)!,
      superficieMid:   Color.lerp(superficieMid,   other.superficieMid,   t)!,
      bordeInactivo:   Color.lerp(bordeInactivo,   other.bordeInactivo,   t)!,
      naranjaTenue:    Color.lerp(naranjaTenue,     other.naranjaTenue,    t)!,
      naranjaGlow:     Color.lerp(naranjaGlow,      other.naranjaGlow,     t)!,
    );
  }
}

/// Acceso rápido: `context.c.textoPrimario`
extension AppColorsX on BuildContext {
  AppColors get c =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}

// ─── AppTheme ─────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  // ── Paleta MAXSO (constantes estáticas — se mantienen para código legacy) ──
  static const Color negro           = Color(0xFF091628);
  static const Color superficieBase  = Color(0xFF0E1D34);
  static const Color superficieCard  = Color(0xFF152740);
  static const Color superficieMid   = Color(0xFF1C3254);

  static const Color naranjaPrimario   = Color(0xFFF06428);
  static const Color naranjaSecundario = Color(0xFFCC5020);
  static const Color naranjaTenue      = Color(0xFF2C1508);
  static const Color naranjaGlow       = Color(0x44F06428);

  static const Color verdePrimario   = naranjaPrimario;
  static const Color verdeSecundario = naranjaSecundario;
  static const Color verdeTenue      = naranjaTenue;
  static const Color verdeGlow       = naranjaGlow;

  static const Color textoPrimario   = Color(0xFFFFFFFF);
  static const Color textoSecundario = Color(0xFF8CB4D6);
  static const Color textoMuted      = Color(0xFF3C5878);

  static const Color bordeActivo   = Color(0xFFF06428);
  static const Color bordeInactivo = Color(0x50F06428);

  static const Color error  = Color(0xFFFF4444);
  static const Color exito  = Color(0xFF4CAF50);

  static const Color azulPrimario    = naranjaPrimario;
  static const Color azulSecundario  = naranjaSecundario;
  static const Color azulClaro       = naranjaTenue;
  static const Color azulMedium      = textoSecundario;
  static const Color blanco          = textoPrimario;
  static const Color grisClaro       = superficieBase;
  static const Color grisMedium      = textoMuted;
  static const Color grisDark        = textoSecundario;
  static const Color glassBackground     = superficieCard;
  static const Color glassBorder         = bordeInactivo;
  static const Color glassShadow         = naranjaGlow;
  static const Color glassBackgroundDark = superficieCard;
  static const Color glassBorderDark     = bordeInactivo;

  // ── Espaciado ──────────────────────────────────────────────────────────────
  static const double borderRadius   = 8.0;
  static const double borderRadiusSm = 6.0;
  static const double borderRadiusLg = 12.0;

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static const String _font = 'Courier New';

  // ── Temas públicos ─────────────────────────────────────────────────────────
  static ThemeData get light => _lightTheme;
  static ThemeData get dark  => _darkTheme;

  // ── Tema oscuro ────────────────────────────────────────────────────────────
  static ThemeData get _darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        extensions: const [AppColors.dark],
        colorScheme: const ColorScheme.dark(
          primary: naranjaPrimario,
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: naranjaTenue,
          onPrimaryContainer: naranjaPrimario,
          secondary: naranjaSecundario,
          onSecondary: Color(0xFFFFFFFF),
          surface: superficieCard,
          onSurface: textoPrimario,
          onSurfaceVariant: textoSecundario,
          outline: bordeInactivo,
          outlineVariant: textoMuted,
          error: error,
          onError: Color(0xFFFFFFFF),
          shadow: Colors.black,
          scrim: Colors.black87,
        ),
        scaffoldBackgroundColor: negro,
        fontFamily: _font,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A1628),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontFamily: _font,
            color: naranjaPrimario,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: naranjaPrimario),
          actionsIconTheme: IconThemeData(color: naranjaPrimario),
        ),
        cardTheme: CardThemeData(
          color: superficieCard,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            side: const BorderSide(color: bordeInactivo),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: naranjaPrimario,
            foregroundColor: Color(0xFFFFFFFF),
            disabledBackgroundColor: superficieMid,
            disabledForegroundColor: textoMuted,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
                horizontal: spacingLg, vertical: spacingMd),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusSm),
            ),
            textStyle: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: naranjaPrimario,
            side: const BorderSide(color: bordeInactivo),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusSm),
            ),
            textStyle: const TextStyle(fontFamily: _font, fontSize: 13),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: superficieMid,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: bordeInactivo),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: bordeInactivo),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: naranjaPrimario, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: error),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: spacingMd, vertical: spacingMd),
          hintStyle: const TextStyle(color: textoMuted, fontFamily: _font, fontSize: 13),
          labelStyle: const TextStyle(color: textoSecundario, fontFamily: _font, fontSize: 13),
          prefixIconColor: textoSecundario,
          suffixIconColor: textoMuted,
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: const TextStyle(
              fontFamily: _font, color: textoPrimario, fontSize: 13),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(superficieCard),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusSm),
              side: const BorderSide(color: bordeInactivo),
            )),
          ),
        ),
        dividerTheme: const DividerThemeData(
            color: bordeInactivo, thickness: 1, space: 1),
        iconTheme: const IconThemeData(color: textoSecundario),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: superficieCard,
          contentTextStyle: const TextStyle(
              fontFamily: _font, color: textoPrimario, fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            side: const BorderSide(color: bordeInactivo),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: textoPrimario,
          iconColor: textoSecundario,
        ),
        textTheme: const TextTheme(
          displayLarge:  TextStyle(fontFamily: _font, color: naranjaPrimario, letterSpacing: 1.0),
          displayMedium: TextStyle(fontFamily: _font, color: naranjaPrimario, letterSpacing: 1.0),
          displaySmall:  TextStyle(fontFamily: _font, color: naranjaPrimario, letterSpacing: 1.0),
          headlineLarge:  TextStyle(fontFamily: _font, color: textoPrimario, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontFamily: _font, color: textoPrimario, fontWeight: FontWeight.w700),
          headlineSmall:  TextStyle(fontFamily: _font, color: textoPrimario, fontWeight: FontWeight.w700),
          titleLarge:  TextStyle(fontFamily: _font, color: textoPrimario, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontFamily: _font, color: textoPrimario, fontWeight: FontWeight.w600),
          titleSmall:  TextStyle(fontFamily: _font, color: textoSecundario, fontSize: 12),
          bodyLarge:   TextStyle(fontFamily: _font, color: textoPrimario),
          bodyMedium:  TextStyle(fontFamily: _font, color: textoPrimario),
          bodySmall:   TextStyle(fontFamily: _font, color: textoSecundario, fontSize: 12),
          labelLarge:  TextStyle(fontFamily: _font, color: textoPrimario, fontWeight: FontWeight.w600, letterSpacing: 0.8),
          labelMedium: TextStyle(fontFamily: _font, color: textoSecundario, letterSpacing: 0.5),
          labelSmall:  TextStyle(fontFamily: _font, color: textoMuted, fontSize: 11),
        ),
      );

  // ── Tema claro ─────────────────────────────────────────────────────────────
  static const _lightNavy  = Color(0xFF091628);
  static const _midNavy    = Color(0xFF1C3254);
  static const _mutedNavy  = Color(0xFF557898);
  static const _cardLight  = Color(0xFFF0F5FC);
  static const _fillLight  = Color(0xFFE2EEF8);
  static const _borderLight = Color(0x80F06428);

  static ThemeData get _lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        extensions: const [AppColors.light],
        colorScheme: const ColorScheme.light(
          primary: naranjaPrimario,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFFFF0E8),
          onPrimaryContainer: naranjaSecundario,
          secondary: naranjaSecundario,
          onSecondary: Colors.white,
          surface: _cardLight,
          onSurface: _lightNavy,
          onSurfaceVariant: _midNavy,
          outline: _borderLight,
          outlineVariant: _mutedNavy,
          error: error,
          onError: Colors.white,
          shadow: Colors.black26,
          scrim: Colors.black38,
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: _font,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          shadowColor: Color(0x1AF06428),
          titleTextStyle: TextStyle(
            fontFamily: _font,
            color: _lightNavy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: naranjaPrimario),
          actionsIconTheme: IconThemeData(color: naranjaPrimario),
        ),
        cardTheme: CardThemeData(
          color: _cardLight,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            side: const BorderSide(color: _borderLight),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: naranjaPrimario,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _fillLight,
            disabledForegroundColor: _mutedNavy,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
                horizontal: spacingLg, vertical: spacingMd),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusSm),
            ),
            textStyle: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _lightNavy,
            side: const BorderSide(color: _borderLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusSm),
            ),
            textStyle: const TextStyle(fontFamily: _font, fontSize: 13),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _fillLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: _borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: _borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: naranjaPrimario, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
            borderSide: const BorderSide(color: error),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: spacingMd, vertical: spacingMd),
          hintStyle: const TextStyle(color: _mutedNavy, fontFamily: _font, fontSize: 13),
          labelStyle: const TextStyle(color: _midNavy, fontFamily: _font, fontSize: 13),
          prefixIconColor: _midNavy,
          suffixIconColor: _mutedNavy,
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: const TextStyle(
              fontFamily: _font, color: _lightNavy, fontSize: 13),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(_cardLight),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusSm),
              side: const BorderSide(color: _borderLight),
            )),
          ),
        ),
        dividerTheme: const DividerThemeData(
            color: _borderLight, thickness: 1, space: 1),
        iconTheme: const IconThemeData(color: _midNavy),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _lightNavy,
          contentTextStyle: const TextStyle(
              fontFamily: _font, color: Colors.white, fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusSm),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        listTileTheme: const ListTileThemeData(
          textColor: _lightNavy,
          iconColor: _midNavy,
        ),
        textTheme: const TextTheme(
          displayLarge:  TextStyle(fontFamily: _font, color: naranjaPrimario, letterSpacing: 1.0),
          displayMedium: TextStyle(fontFamily: _font, color: naranjaPrimario, letterSpacing: 1.0),
          displaySmall:  TextStyle(fontFamily: _font, color: naranjaPrimario, letterSpacing: 1.0),
          headlineLarge:  TextStyle(fontFamily: _font, color: _lightNavy, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontFamily: _font, color: _lightNavy, fontWeight: FontWeight.w700),
          headlineSmall:  TextStyle(fontFamily: _font, color: _lightNavy, fontWeight: FontWeight.w700),
          titleLarge:  TextStyle(fontFamily: _font, color: _lightNavy, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontFamily: _font, color: _lightNavy, fontWeight: FontWeight.w600),
          titleSmall:  TextStyle(fontFamily: _font, color: _midNavy, fontSize: 12),
          bodyLarge:   TextStyle(fontFamily: _font, color: _lightNavy),
          bodyMedium:  TextStyle(fontFamily: _font, color: _lightNavy),
          bodySmall:   TextStyle(fontFamily: _font, color: _midNavy, fontSize: 12),
          labelLarge:  TextStyle(fontFamily: _font, color: _lightNavy, fontWeight: FontWeight.w600, letterSpacing: 0.8),
          labelMedium: TextStyle(fontFamily: _font, color: _midNavy, letterSpacing: 0.5),
          labelSmall:  TextStyle(fontFamily: _font, color: _mutedNavy, fontSize: 11),
        ),
      );
}

// ─── GlassCard (tema-adaptable) ───────────────────────────────────────────────

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
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c.superficieCard,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: c.bordeInactivo, width: 1),
          boxShadow: [
            BoxShadow(
              color: c.naranjaGlow,
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 2),
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

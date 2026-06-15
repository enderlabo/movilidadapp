import 'package:flutter/material.dart';

/// Sistema de diseño MAXSO: azul marino corporativo + naranja acento.
abstract final class AppTheme {
  // ─── Paleta MAXSO ─────────────────────────────────────────────────────────
  static const Color negro           = Color(0xFF091628); // navy profundo
  static const Color superficieBase  = Color(0xFF0E1D34); // navy oscuro
  static const Color superficieCard  = Color(0xFF152740); // navy medio
  static const Color superficieMid   = Color(0xFF1C3254); // navy claro

  static const Color naranjaPrimario   = Color(0xFFF06428); // naranja MAXSO
  static const Color naranjaSecundario = Color(0xFFCC5020); // naranja oscuro
  static const Color naranjaTenue      = Color(0xFF2C1508); // fondo badges naranja
  static const Color naranjaGlow       = Color(0x44F06428); // sombra/glow

  // Alias semánticos (mantienen compatibilidad con código existente) ─────────
  static const Color verdePrimario   = naranjaPrimario;
  static const Color verdeSecundario = naranjaSecundario;
  static const Color verdeTenue      = naranjaTenue;
  static const Color verdeGlow       = naranjaGlow;

  static const Color textoPrimario   = Color(0xFFFFFFFF);  // blanco
  static const Color textoSecundario = Color(0xFF8CB4D6);  // azul grisáceo claro
  static const Color textoMuted      = Color(0xFF3C5878);  // azul grisáceo oscuro

  static const Color bordeActivo     = Color(0xFFF06428);
  static const Color bordeInactivo   = Color(0x50F06428); // naranja 31%

  static const Color error           = Color(0xFFFF4444); // rojo
  static const Color exito           = Color(0xFF4CAF50); // verde éxito

  // Aliases para compatibilidad con código existente ─────────────────────────
  static const Color azulPrimario    = naranjaPrimario;
  static const Color azulSecundario  = naranjaSecundario;
  static const Color azulClaro       = naranjaTenue;
  static const Color azulMedium      = textoSecundario;
  static const Color blanco          = textoPrimario;
  static const Color grisClaro       = superficieBase;
  static const Color grisMedium      = textoMuted;
  static const Color grisDark        = textoSecundario;
  static const Color glassBackground = superficieCard;
  static const Color glassBorder     = bordeInactivo;
  static const Color glassShadow     = naranjaGlow;
  static const Color glassBackgroundDark = superficieCard;
  static const Color glassBorderDark = bordeInactivo;

  // ─── Espaciado ────────────────────────────────────────────────────────────
  static const double borderRadius   = 8.0;
  static const double borderRadiusSm = 6.0;
  static const double borderRadiusLg = 12.0;

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ─── Fuente ──────────────────────────────────────────────────────────────
  static const String _font = 'Courier New';

  // ─── Tema ────────────────────────────────────────────────────────────────
  static ThemeData get light => _maxsoTheme;
  static ThemeData get dark  => _maxsoTheme;

  static ThemeData get _maxsoTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
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
          hintStyle: const TextStyle(
              color: textoMuted, fontFamily: _font, fontSize: 13),
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
          displayLarge: TextStyle(
              fontFamily: _font, color: naranjaPrimario, letterSpacing: 1.0),
          displayMedium: TextStyle(
              fontFamily: _font, color: naranjaPrimario, letterSpacing: 1.0),
          displaySmall: TextStyle(
              fontFamily: _font, color: naranjaPrimario, letterSpacing: 1.0),
          headlineLarge: TextStyle(
              fontFamily: _font,
              color: textoPrimario,
              fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(
              fontFamily: _font,
              color: textoPrimario,
              fontWeight: FontWeight.w700),
          headlineSmall: TextStyle(
              fontFamily: _font,
              color: textoPrimario,
              fontWeight: FontWeight.w700),
          titleLarge: TextStyle(
              fontFamily: _font,
              color: textoPrimario,
              fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              fontFamily: _font,
              color: textoPrimario,
              fontWeight: FontWeight.w600),
          titleSmall: TextStyle(
              fontFamily: _font, color: textoSecundario, fontSize: 12),
          bodyLarge: TextStyle(fontFamily: _font, color: textoPrimario),
          bodyMedium: TextStyle(fontFamily: _font, color: textoPrimario),
          bodySmall: TextStyle(
              fontFamily: _font, color: textoSecundario, fontSize: 12),
          labelLarge: TextStyle(
              fontFamily: _font,
              color: textoPrimario,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8),
          labelMedium: TextStyle(
              fontFamily: _font, color: textoSecundario, letterSpacing: 0.5),
          labelSmall: TextStyle(
              fontFamily: _font, color: textoMuted, fontSize: 11),
        ),
      );
}

/// Panel / card con borde naranja y glow marino.
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.superficieCard,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: AppTheme.bordeInactivo, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.naranjaGlow,
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// DRY: un único lugar donde vive la lógica de detección de plataforma.
/// Nunca uses kIsWeb o Platform.isAndroid directamente en widgets.
abstract final class PlatformUtils {
  /// True si la pantalla es de ancho móvil (<600px) O es dispositivo móvil.
  static bool isMobile(BuildContext context) {
    if (kIsWeb) {
      return MediaQuery.sizeOf(context).width < 600;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool isDesktop(BuildContext context) => !isMobile(context);

  static bool get isWeb => kIsWeb;

  /// Padding superior adaptativo (safe area en mobile, toolbar en desktop).
  static double topPadding(BuildContext context) =>
      isMobile(context) ? MediaQuery.paddingOf(context).top : 0;
}

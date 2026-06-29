import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/routes/domain/entities/route.dart';

/// Genera enlaces universales de Google Maps a partir de una [RouteResult] para
/// que otro usuario pueda abrir y visualizar la ruta recomendada en su propia
/// app de Google Maps (móvil) o navegador (escritorio).
///
/// Usa el esquema universal de Google Maps Directions:
/// https://developers.google.com/maps/documentation/urls/get-started#directions-action
class RouteShareService {
  const RouteShareService();

  /// Construye el enlace de direcciones de Google Maps para [route].
  ///
  /// Toma únicamente el origen y el destino de los extremos de la polilínea para
  /// que el receptor vea una ruta limpia (un solo origen y un solo destino), sin
  /// paradas intermedias. Google Maps trazará su mejor ruta de conducción entre
  /// ambos puntos.
  String googleMapsUrl(RouteResult route) {
    final pts = route.polilinea;
    if (pts.length < 2) {
      throw StateError('La ruta no tiene suficientes puntos para compartir.');
    }
    final origen = pts.first;
    final destino = pts.last;

    final params = <String, String>{
      'api': '1',
      'origin': '${origen.lat},${origen.lng}',
      'destination': '${destino.lat},${destino.lng}',
      'travelmode': 'driving',
    };

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'https://www.google.com/maps/dir/?$query';
  }

  /// Abre la hoja de compartir nativa del sistema (WhatsApp, correo, etc.) con
  /// el enlace de [route]. Es la vía recomendada para enviar la ruta a otro
  /// usuario: él recibe el link y, al abrirlo, ve la ruta en su Google Maps.
  ///
  /// [origin] es opcional y solo lo usan iPad/macOS para anclar el popover de
  /// la hoja de compartir.
  Future<void> compartir(RouteResult route, {Rect? origin}) async {
    final url = googleMapsUrl(route);
    await SharePlus.instance.share(
      ShareParams(
        text: url,
        subject: 'Ruta recomendada — ${route.etiqueta}',
        sharePositionOrigin: origin,
      ),
    );
  }

  /// Copia el enlace de [route] al portapapeles para pegarlo en cualquier app
  /// (WhatsApp, correo, etc.).
  Future<String> copiarEnlace(RouteResult route) async {
    final url = googleMapsUrl(route);
    await Clipboard.setData(ClipboardData(text: url));
    return url;
  }

  /// Abre la ruta directamente en Google Maps (app o navegador).
  /// Devuelve `false` si la plataforma no pudo lanzar la URL.
  Future<bool> abrirEnMaps(RouteResult route) async {
    final uri = Uri.parse(googleMapsUrl(route));
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

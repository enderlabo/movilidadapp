import 'package:freezed_annotation/freezed_annotation.dart';

part 'route.freezed.dart';

/// Una ruta retornada por Google Maps Routes API.
/// El dominio no sabe si vino del SDK móvil o de la JS API web.
@freezed
class RouteResult with _$RouteResult {
  const factory RouteResult({
    required String id,
    required String etiqueta,          // "Ruta más rápida", "Ruta alternativa"
    required double distanciaKm,
    required Duration duracionEstimada,
    required double peajesEstimadosSoles, // estimado Maps; puede ser 0 si sin cobertura
    required bool tienePeajesConfiables,  // false si Maps no tiene datos para Perú
    required List<PuntoRuta> polilinea,   // para dibujar en el mapa
    required String resumenRuta,          // "Panamericana Norte"
  }) = _RouteResult;
}

@freezed
class PuntoRuta with _$PuntoRuta {
  const factory PuntoRuta({
    required double lat,
    required double lng,
  }) = _PuntoRuta;
}

/// Par origen–destino que el usuario ingresa.
@freezed
class Waypoint with _$Waypoint {
  const factory Waypoint({
    required String direccion,     // texto legible
    required double lat,
    required double lng,
  }) = _Waypoint;
}

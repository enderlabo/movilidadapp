import 'dart:math';
import '../entities/toll.dart';

/// Resultado del proceso de matching para UN peaje detectado por Maps.
class TollMatchResult {
  final TollDetectado detectado;     // lo que Maps vio
  final Toll? catalogMatch;          // peaje del catálogo si hubo match
  final double montoAUsar;           // monto final para el cálculo
  final bool requiereConfirmacion;   // true si la jefa debe revisar

  const TollMatchResult({
    required this.detectado,
    required this.catalogMatch,
    required this.montoAUsar,
    required this.requiereConfirmacion,
  });

  bool get estaEnCatalogo => catalogMatch != null;
  bool get estaConfirmado =>
      catalogMatch?.fuente == TollFuente.confirmadoJefa ||
      catalogMatch?.fuente == TollFuente.ingresadoManual;
}

/// Un peaje tal como lo retorna Google Maps Routes API.
class TollDetectado {
  final String nombre;
  final double lat;
  final double lng;
  final double montoEstimadoSoles; // 0 si Maps no tiene datos para Perú

  const TollDetectado({
    required this.nombre,
    required this.lat,
    required this.lng,
    required this.montoEstimadoSoles,
  });
}

/// Servicio de dominio puro — no tiene I/O, solo lógica.
///
/// KISS: matching por proximidad geográfica + nombre fuzzy.
/// DRY: la lógica de matching está aquí y solo aquí.
class TollMatcherService {
  /// Radio máximo en km para considerar que dos peajes son el mismo punto.
  static const double _radioMatchKm = 0.5;

  const TollMatcherService();

  /// Procesa los peajes detectados por Maps contra el catálogo local.
  ///
  /// Para cada peaje detectado:
  ///   1. Busca en el catálogo por proximidad geográfica.
  ///   2. Si hay match confirmado → usa monto del catálogo.
  ///   3. Si hay match sin confirmar → usa monto del catálogo pero marca para revisar.
  ///   4. Si no hay match → usa estimado de Maps, marca para agregar al catálogo.
  List<TollMatchResult> matchTolls({
    required List<TollDetectado> detectados,
    required List<Toll> catalogo,
    required TipoVehiculo tipoVehiculo,
  }) {
    return detectados.map((detectado) {
      final match = _buscarEnCatalogo(detectado, catalogo);

      if (match == null) {
        // No está en catálogo — nuevo peaje, necesita ser registrado
        return TollMatchResult(
          detectado: detectado,
          catalogMatch: null,
          montoAUsar: detectado.montoEstimadoSoles,
          requiereConfirmacion: true,
        );
      }

      final tarifaCatalogo = match.tarifaPara(tipoVehiculo);

      if (tarifaCatalogo == null) {
        // Está en catálogo pero sin tarifa para este tipo de vehículo
        return TollMatchResult(
          detectado: detectado,
          catalogMatch: match,
          montoAUsar: detectado.montoEstimadoSoles,
          requiereConfirmacion: true,
        );
      }

      // Está en catálogo con tarifa — usar monto del catálogo
      return TollMatchResult(
        detectado: detectado,
        catalogMatch: match,
        montoAUsar: tarifaCatalogo,
        requiereConfirmacion: match.fuente.requiereConfirmacion,
      );
    }).toList();
  }

  /// Convierte los resultados del matching en snapshots para el cálculo.
  /// [overrides] permite que la jefa corrija montos antes de calcular.
  List<TollSnapshot> buildSnapshots({
    required List<TollMatchResult> matchResults,
    Map<String, double>? overrides, // tollId → monto corregido por jefa
  }) {
    return matchResults.map((result) {
      final tollId = result.catalogMatch?.id ?? _generarIdTemporal(result.detectado);
      final montoOverride = overrides?[tollId];
      final montoFinal = montoOverride ?? result.montoAUsar;

      return TollSnapshot(
        tollId: tollId,
        nombre: result.detectado.nombre,
        montoOriginalMaps: result.detectado.montoEstimadoSoles,
        montoUsado: montoFinal,
        fueCorregidoPorJefa: montoOverride != null,
        fuente: result.catalogMatch?.fuente ?? TollFuente.detectadoMaps,
      );
    }).toList();
  }

  /// Suma total de peajes para una lista de snapshots.
  double totalPeajesSoles(List<TollSnapshot> snapshots) =>
      snapshots.fold(0, (sum, s) => sum + s.montoUsado);

  /// ─── Privados ────────────────────────────────────────────────────────────

  Toll? _buscarEnCatalogo(TollDetectado detectado, List<Toll> catalogo) {
    // Primero: match por proximidad geográfica (más confiable que nombre)
    final porProximidad = catalogo.where((toll) {
      final distancia = _distanciaKm(
        detectado.lat, detectado.lng,
        toll.lat, toll.lng,
      );
      return distancia <= _radioMatchKm;
    }).toList();

    if (porProximidad.isEmpty) return null;
    if (porProximidad.length == 1) return porProximidad.first;

    // Si hay varios cercanos, desempata por similitud de nombre
    return porProximidad.reduce((a, b) {
      final simA = _similitudNombre(detectado.nombre, a.nombre);
      final simB = _similitudNombre(detectado.nombre, b.nombre);
      return simA >= simB ? a : b;
    });
  }

  /// Haversine — distancia en km entre dos coordenadas.
  double _distanciaKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // radio de la Tierra en km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;

  /// Similitud simple por palabras comunes — suficiente para nombres de peajes.
  double _similitudNombre(String a, String b) {
    final wordsA = a.toLowerCase().split(RegExp(r'\s+'));
    final wordsB = b.toLowerCase().split(RegExp(r'\s+'));
    final comunes = wordsA.where(wordsB.contains).length;
    return comunes / max(wordsA.length, wordsB.length);
  }

  String _generarIdTemporal(TollDetectado detectado) =>
      'temp_${detectado.lat}_${detectado.lng}';
}

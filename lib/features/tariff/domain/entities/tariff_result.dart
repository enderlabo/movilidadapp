import 'package:freezed_annotation/freezed_annotation.dart';

part 'tariff_result.freezed.dart';

/// Resultado de tarifa calculado para UNA ruta específica.
/// Se generan tantos [TariffResult] como rutas retorne Maps (≥2).
@freezed
class TariffResult with _$TariffResult {
  const factory TariffResult({
    required String routeId,
    required String routeEtiqueta,

    // Combustible — ida (cargado) + vuelta (vacío)
    required double combustibleIdaGalones,
    required double combustibleVueltaGalones,
    required double combustibleIdaSoles,
    required double combustibleVueltaSoles,

    // Peajes
    required double peajesTotalesSoles,
    required bool peajesAjustadosManualmente,

    // Totales
    required double totalSoles,
    required double totalDolares,
    required double tipoCambioUsado,

    // Metadata para mostrar en UI
    required double distanciaKm,
    required Duration duracionEstimada,
    required DateTime calculadoEn,
  }) = _TariffResult;

  const TariffResult._();

  double get totalCombustibleSoles => combustibleIdaSoles + combustibleVueltaSoles;

  double get combustibleTotalGalones =>
      combustibleIdaGalones + combustibleVueltaGalones;
}

/// Desglose de una cotización completa (puede tener ≥2 rutas).
@freezed
class Quotation with _$Quotation {
  const factory Quotation({
    required String id,
    required String vehiculoId,
    required String vehiculoNombre,
    required String origenDireccion,
    required String destinoDireccion,
    required List<TariffResult> resultadosPorRuta,
    required double precioGalonUsado,
    required DateTime creadaEn,
    String? notasAdicionales,
  }) = _Quotation;

  const Quotation._();

  /// Ruta más económica del conjunto.
  TariffResult get rutaMasEconomica => resultadosPorRuta
      .reduce((a, b) => a.totalSoles < b.totalSoles ? a : b);
}

// NOTA: TariffResult debe incluir List<TollSnapshot> peajesDetallados
// al integrarse con la feature de tolls. Se omite aquí para no crear
// dependencia circular entre features en el scaffold inicial.
// La integración se hace en CalculateTariffUseCase vía TollSnapshots.

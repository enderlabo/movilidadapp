import '../entities/cotizacion_tarifario.dart';
import '../../../tariff/domain/entities/tarifa_config.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

/// Pure domain service — no I/O, no Flutter, 100% testable.
///
/// Single source of truth for the quotation formula (DRY): it used to live
/// inside `TariffViewModel`, breaking Clean Architecture's dependency rule.
///
/// Operating model: the price covers the round trip, so km, time and weight are
/// multiplied by [_roundTripFactor].
class CotizacionCalculatorService {
  const CotizacionCalculatorService();

  /// Round-trip multiplier applied to km, time and weight.
  static const double _roundTripFactor = 2;

  CotizacionTarifario calcular({
    required String id,
    required Vehicle vehiculo,
    required TarifaConfig config,
    required double distanciaKm,
    required double pesoKg,
    required Duration duracionEstimada,
    required String origenDireccion,
    required String destinoDireccion,
    required DateTime generadaEn,
  }) {
    final tarifaPorKm = config.tarifaPara(vehiculo.id);
    final costoBaseKm = tarifaPorKm * distanciaKm;
    final costoKilometraje = costoBaseKm * _roundTripFactor;
    final costoTiempo = costoBaseKm * config.factorTiempo * _roundTripFactor;
    final costoPeso = pesoKg * config.tarifaPorKg * _roundTripFactor;
    final precioTotal = costoKilometraje + costoTiempo + costoPeso;

    return CotizacionTarifario(
      id: id,
      categoria: vehiculo.categoria,
      vehiculoNombre: vehiculo.nombre,
      origenDireccion: origenDireccion,
      destinoDireccion: destinoDireccion,
      tarifaPorKm: tarifaPorKm,
      distanciaKm: distanciaKm,
      costoKilometraje: costoKilometraje,
      costoTiempo: costoTiempo,
      pesoKg: pesoKg,
      costoPeso: costoPeso,
      precioTotal: precioTotal,
      duracionEstimada: duracionEstimada,
      generadaEn: generadaEn,
    );
  }
}

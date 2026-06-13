import '../entities/tariff_result.dart';
import '../../../routes/domain/entities/route.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

/// Servicio de dominio puro — sin I/O, sin Flutter, 100% testeable.
///
/// KISS: cada método hace exactamente una cosa.
/// DRY: la fórmula de combustible está en un único lugar.
class TariffCalculatorService {
  const TariffCalculatorService();

  /// Calcula el costo de combustible para un tramo.
  ///
  /// [distanciaKm]    — distancia del tramo.
  /// [conCarga]       — true = rendimiento cargado, false = rendimiento vacío.
  /// [precioGalonS/]  — precio actual del galón en soles (OSINERGMIN).
  double calcularCombustibleSoles({
    required double distanciaKm,
    required Vehicle vehicle,
    required bool conCarga,
    required double precioGalonSoles,
  }) {
    final rendimiento = vehicle.rendimientoPara(conCarga: conCarga);
    final galones = distanciaKm / rendimiento;
    return galones * precioGalonSoles;
  }

  /// Calcula la tarifa completa para una ruta.
  ///
  /// Modelo operativo:
  ///   IDA  → almacén → cliente (CARGADO)
  ///   VUELTA → cliente → almacén (VACÍO)
  TariffResult calcularParaRuta({
    required RouteResult route,
    required Vehicle vehicle,
    required double precioGalonSoles,
    required double tipoCambio,
    double? peajesOverrideSoles, // override manual si Maps no tiene cobertura
  }) {
    // Combustible ida (cargado)
    final combustibleIdaGalones =
        route.distanciaKm / vehicle.rendimientoKmPorGalonCargado;
    final combustibleIdaSoles =
        combustibleIdaGalones * precioGalonSoles;

    // Combustible vuelta (vacío)
    final combustibleVueltaGalones =
        route.distanciaKm / vehicle.rendimientoKmPorGalonVacio;
    final combustibleVueltaSoles =
        combustibleVueltaGalones * precioGalonSoles;

    // Peajes: usar override manual o estimado Maps
    final peajesTotalesSoles =
        peajesOverrideSoles ?? route.peajesEstimadosSoles;
    final peajesAjustados = peajesOverrideSoles != null;

    // Total
    final totalSoles =
        combustibleIdaSoles + combustibleVueltaSoles + peajesTotalesSoles;
    final totalDolares = totalSoles / tipoCambio;

    return TariffResult(
      routeId: route.id,
      routeEtiqueta: route.etiqueta,
      combustibleIdaGalones: combustibleIdaGalones,
      combustibleVueltaGalones: combustibleVueltaGalones,
      combustibleIdaSoles: combustibleIdaSoles,
      combustibleVueltaSoles: combustibleVueltaSoles,
      peajesTotalesSoles: peajesTotalesSoles,
      peajesAjustadosManualmente: peajesAjustados,
      totalSoles: totalSoles,
      totalDolares: totalDolares,
      tipoCambioUsado: tipoCambio,
      distanciaKm: route.distanciaKm,
      duracionEstimada: route.duracionEstimada,
      calculadoEn: DateTime.now(),
    );
  }

  /// Calcula la tarifa para TODAS las rutas retornadas por Maps.
  List<TariffResult> calcularParaTodasLasRutas({
    required List<RouteResult> routes,
    required Vehicle vehicle,
    required double precioGalonSoles,
    required double tipoCambio,
    Map<String, double>? peajesOverridePorRuta,
  }) {
    return routes.map((route) {
      return calcularParaRuta(
        route: route,
        vehicle: vehicle,
        precioGalonSoles: precioGalonSoles,
        tipoCambio: tipoCambio,
        peajesOverrideSoles: peajesOverridePorRuta?[route.id],
      );
    }).toList();
  }
}

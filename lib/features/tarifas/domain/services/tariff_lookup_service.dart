import '../entities/tarifa_zona.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

class TariffLookupService {
  const TariffLookupService();

  TarifaZona? buscar({
    required String distritoOrigen,
    required String distritoDestino,
    required CategoriaVehiculo categoria,
    required List<TarifaZona> tarifas,
  }) {
    final activas = tarifas.where((t) => t.activo).toList();
    final o = _n(distritoOrigen);
    final d = _n(distritoDestino);

    // Match exacto (normalizado)
    TarifaZona? match = activas.where((t) =>
      _n(t.distritoOrigen) == o &&
      _n(t.distritoDestino) == d &&
      t.categoria == categoria,
    ).firstOrNull;

    if (match != null) return match;

    // Match inverso — entrega y recojo es simétrico
    match = activas.where((t) =>
      _n(t.distritoOrigen) == d &&
      _n(t.distritoDestino) == o &&
      t.categoria == categoria,
    ).firstOrNull;

    if (match != null) return match;

    // Match parcial: alguna tarifa cuyo origen contenga el distrito detectado
    // Útil cuando el geocoding retorna un nombre ligeramente distinto
    match = activas.where((t) =>
      (_n(t.distritoOrigen).contains(o) || o.contains(_n(t.distritoOrigen))) &&
      (_n(t.distritoDestino).contains(d) || d.contains(_n(t.distritoDestino))) &&
      t.categoria == categoria,
    ).firstOrNull;

    return match;
  }

  /// Normaliza: minúsculas + trim + quita "distrito de " al inicio
  static String _n(String s) => s
      .toLowerCase()
      .trim()
      .replaceFirst(RegExp(r'^distrito de '), '');
}

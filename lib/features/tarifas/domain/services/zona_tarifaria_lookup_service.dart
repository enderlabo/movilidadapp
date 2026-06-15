import '../entities/zona_tarifaria.dart';

class ZonaTarifariaLookupService {
  const ZonaTarifariaLookupService();

  ZonaTarifaria? buscarZonaPorDistrito(
    String distrito,
    List<ZonaTarifaria> zonas,
  ) {
    final d = _n(distrito);
    final activas = zonas.where((z) => z.activo).toList();

    // Búsqueda exacta normalizada
    final exacta = activas
        .where((z) => z.distritos.any((dist) => _n(dist) == d))
        .firstOrNull;
    if (exacta != null) return exacta;

    // Búsqueda parcial (contiene)
    return activas
        .where((z) => z.distritos.any(
              (dist) => _n(dist).contains(d) || d.contains(_n(dist)),
            ))
        .firstOrNull;
  }

  static String _n(String s) =>
      s.toLowerCase().trim().replaceFirst(RegExp(r'^distrito de '), '');
}

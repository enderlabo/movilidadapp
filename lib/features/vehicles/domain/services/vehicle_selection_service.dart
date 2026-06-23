import '../entities/vehicle.dart';
import '../entities/vehicle_recommendation.dart';

/// Servicio puro de dominio — sin I/O, 100% testeable.
///
/// Aplica la Matriz de Selección de Vehículo (Forland 190 vs Dongfeng DF-814)
/// según zona de Lima y peso de carga.
///
/// La zona se determina en DOS pasos:
///   1. Por distrito del destino (geocodificación).
///   2. Si la ruta obtenida de Maps usa una vía de alta velocidad
///      (Vía de Evitamiento, Panamericana, etc.), el resumen de ruta
///      sobreescribe la zona del distrito → ZonaLima.altaVelocidad.
///
/// Regla de las 1.5t: carga ligera en zona residencial → Forland (BSL-831).
/// Regla de ahorro GNV: resto de zonas → Dongfeng (CCK-886) independiente del peso.
class VehicleSelectionService {
  static const placaForland = 'BSL-831';
  static const placaDongfeng = 'CCK-886';

  static const _pesoLimiteKg = 1500.0;

  const VehicleSelectionService();

  /// Recomendación solo por distrito (antes de obtener rutas de Maps).
  VehicleRecommendation recomendar({
    required String distritoDestino,
    required double pesoKg,
  }) =>
      recomendarConRuta(
        distritoDestino: distritoDestino,
        pesoKg: pesoKg,
      );

  /// Recomendación completa: combina distrito + resumen de ruta de Maps.
  ///
  /// [resumenRuta] — campo `RouteResult.resumenRuta` de la ruta principal
  /// (p.ej. "Vía de Evitamiento", "Panamericana Norte").
  /// Si contiene una vía de alta velocidad, sobreescribe la zona del distrito.
  VehicleRecommendation recomendarConRuta({
    required String distritoDestino,
    required double pesoKg,
    String? resumenRuta,
  }) {
    final zonaDistrito = _detectarZonaPorDistrito(distritoDestino);
    final zona = (resumenRuta != null && _esAltaVelocidad(resumenRuta))
        ? ZonaLima.altaVelocidad
        : zonaDistrito;
    return _aplicarMatriz(zona: zona, pesoKg: pesoKg);
  }

  // ── Detección de zona ─────────────────────────────────────────────────────

  /// Mapea el nombre del distrito (de geocodificación) a su [ZonaLima].
  /// Alta velocidad NO se detecta aquí — depende del resumen de ruta.
  ZonaLima _detectarZonaPorDistrito(String distrito) {
    final d = distrito.toLowerCase().trim();
    if (_residencial.any((s) => d.contains(s))) {
      return ZonaLima.residencialFinanciero;
    }
    if (_comercial.any((s) => d.contains(s))) {
      return ZonaLima.comercialIndustrial;
    }
    if (_periferica.any((s) => d.contains(s))) {
      return ZonaLima.periferica;
    }
    return ZonaLima.comercialIndustrial; // fallback: Dongfeng por eficiencia GNV
  }

  /// Detecta si el resumen de ruta de Google Maps corresponde a una vía
  /// de alta velocidad (libre de restricciones vehiculares).
  bool _esAltaVelocidad(String resumenRuta) {
    final r = resumenRuta.toLowerCase();
    return _altaVelocidadRutas.any((s) => r.contains(s));
  }

  // ── Matriz de selección ───────────────────────────────────────────────────

  VehicleRecommendation _aplicarMatriz({
    required ZonaLima zona,
    required double pesoKg,
  }) {
    final esCargaLigera = pesoKg < _pesoLimiteKg;

    return switch (zona) {
      ZonaLima.residencialFinanciero => esCargaLigera
          ? VehicleRecommendation(
              placaRecomendada: placaForland,
              zona: zona,
              razon:
                  'Calles estrechas y alta fiscalización — mejor maniobrabilidad del Forland',
            )
          : VehicleRecommendation(
              placaRecomendada: placaDongfeng,
              zona: zona,
              razon:
                  'Carga pesada en zona residencial — requiere permiso y horario permitido',
              requierePermisos: true,
            ),
      ZonaLima.comercialIndustrial => VehicleRecommendation(
          placaRecomendada: placaDongfeng,
          zona: zona,
          razon: 'Avenidas anchas — GNV del Dongfeng reduce costos drásticamente',
        ),
      ZonaLima.periferica => VehicleRecommendation(
          placaRecomendada: placaDongfeng,
          zona: zona,
          razon: 'Distancias largas — motor GNV más eficiente en trayectos largos',
        ),
      ZonaLima.altaVelocidad => VehicleRecommendation(
          placaRecomendada: placaDongfeng,
          zona: zona,
          razon: 'Ruta de alta velocidad — motor a gas rinde al máximo sin restricciones',
        ),
    };
  }

  // ── Catálogos ─────────────────────────────────────────────────────────────

  static const _residencial = [
    'san borja', 'miraflores', 'san isidro', 'magdalena', 'jesus maria',
    'jesús maría', 'surco', 'santiago de surco', 'barranco', 'san miguel',
    'pueblo libre', 'lince', 'la molina', 'monterrico',
  ];

  static const _comercial = [
    'santa anita', 'ate', 'san luis', 'la victoria', 'cercado',
    'lima cercado', 'centro de lima', 'breña', 'brena', 'rimac', 'rímac',
    'el agustino', 'san juan de lurigancho', 'sjl', 'lurigancho',
  ];

  static const _periferica = [
    'comas', 'carabayllo', 'independencia', 'los olivos',
    'san juan de miraflores', 'sjm', 'villa el salvador', 'ves',
    'villa maria del triunfo', 'chorrillos', 'lurín', 'lurin',
    'pachacamac', 'puente piedra', 'ventanilla', 'mi peru', 'mi perú',
    'ancon', 'ancón',
  ];

  // Detectado desde RouteResult.resumenRuta, no desde el distrito.
  static const _altaVelocidadRutas = [
    'via de evitamiento', 'vía de evitamiento',
    'panamericana norte', 'panamericana sur',
    'carretera central',
  ];
}

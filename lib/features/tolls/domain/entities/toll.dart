import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

// Re-exports `TipoVehiculo` (previously defined here) so consumers that used to
// get it through this file keep compiling.
export '../../../vehicles/domain/entities/vehicle.dart' show TipoVehiculo;

part 'toll.freezed.dart';

/// Un peaje real del catálogo.
/// Se crea la primera vez que Maps lo detecta y la jefa confirma/corrige el monto.
/// Crece orgánicamente: Lima primero, luego todo Perú.
@freezed
abstract class Toll with _$Toll {
  const factory Toll({
    required String id,
    required String nombre,          // "Peaje Chao", "Variante de Pasamayo"
    required String ubicacion,       // descripción textual de ubicación
    required double lat,
    required double lng,
    required Map<TipoVehiculo, double> tarifasPorTipo, // S/ por tipo de vehículo
    required TollFuente fuente,      // cómo se originó este registro
    required DateTime creadoEn,
    required DateTime actualizadoEn,
    @Default(true) bool activo,
    String? notasAdicionales,        // "Solo cobran en dirección norte"
  }) = _Toll;

  const Toll._();

  /// Tarifa para un tipo de vehículo específico.
  /// Retorna null si el tipo no tiene tarifa registrada aún.
  double? tarifaPara(TipoVehiculo tipo) => tarifasPorTipo[tipo];

  /// Indica si el peaje tiene tarifa confirmada para un tipo de vehículo.
  bool tieneConfirmadoPara(TipoVehiculo tipo) =>
      tarifasPorTipo.containsKey(tipo);
}

/// Origen del registro del peaje en el catálogo.
enum TollFuente {
  detectadoMaps,     // Maps lo detectó, monto sin confirmar por la jefa
  confirmadoJefa,    // la jefa revisó y confirmó/corrigió el monto
  ingresadoManual;   // la jefa lo creó manualmente (Maps no lo detectó)

  String get displayName => switch (this) {
        TollFuente.detectadoMaps => 'Detectado por Maps',
        TollFuente.confirmadoJefa => 'Confirmado',
        TollFuente.ingresadoManual => 'Ingresado manualmente',
      };

  bool get requiereConfirmacion => this == TollFuente.detectadoMaps;
}

// NOTE: `TipoVehiculo` is reused from `vehicles/domain/entities/vehicle.dart`
// (it used to be duplicated here). If tolls ever need their own SUTRAN
// classification, introduce a separate `TipoVehiculoPeaje` enum.

/// Snapshot de un peaje dentro de un cálculo.
/// INMUTABLE — refleja el monto en el momento del cálculo.
/// Aunque la jefa actualice el catálogo después, este snapshot no cambia.
@freezed
abstract class TollSnapshot with _$TollSnapshot {
  const factory TollSnapshot({
    required String tollId,           // referencia al catálogo
    required String nombre,
    required double montoOriginalMaps, // lo que Maps estimó (puede ser 0)
    required double montoUsado,        // lo que se usó en el cálculo
    required bool fueCorregidoPorJefa, // true si montoUsado ≠ montoOriginalMaps
    required TollFuente fuente,
  }) = _TollSnapshot;

  const TollSnapshot._();

  bool get tieneDiferencia => montoOriginalMaps != montoUsado;
  double get diferenciaSoles => montoUsado - montoOriginalMaps;
}

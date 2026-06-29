import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

part 'cotizacion_tarifario.freezed.dart';

@freezed
abstract class CotizacionTarifario with _$CotizacionTarifario {
  const factory CotizacionTarifario({
    required String id,
    required CategoriaVehiculo categoria,
    required String vehiculoNombre,
    required String origenDireccion,
    required String destinoDireccion,
    required double tarifaPorKm,
    required double distanciaKm,
    required double costoKilometraje,
    required double costoTiempo,
    @Default(0.0) double pesoKg,
    @Default(0.0) double costoPeso,
    required double precioTotal,
    required Duration duracionEstimada,
    required DateTime generadaEn,
  }) = _CotizacionTarifario;

  const CotizacionTarifario._();

  String get precioDisplay {
    final v = precioTotal;
    return 'S/ ${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}';
  }

  /// Recargo de tiempo expresado como % del costo de kilometraje.
  double get porcentajeTiempo =>
      costoKilometraje == 0 ? 0 : costoTiempo / costoKilometraje * 100;

  /// Tarifa por kg por tramo (descontando el ×2 de ida + vuelta).
  double get tarifaPorKgUnitaria =>
      pesoKg == 0 ? 0 : costoPeso / pesoKg / 2;
}

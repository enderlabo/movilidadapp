import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

part 'cotizacion_tarifario.freezed.dart';

@freezed
class CotizacionTarifario with _$CotizacionTarifario {
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
}

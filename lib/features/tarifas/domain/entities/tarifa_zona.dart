import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

part 'tarifa_zona.freezed.dart';

@freezed
class TarifaZona with _$TarifaZona {
  const factory TarifaZona({
    required String id,
    required String distritoOrigen,
    required String distritoDestino,
    required CategoriaVehiculo categoria,
    required double precioSoles,
    double? precioMinSoles,
    double? precioMaxSoles,
    @Default(true) bool activo,
  }) = _TarifaZona;

  const TarifaZona._();

  bool get esIntraDistrito => distritoOrigen == distritoDestino;

  String get descripcionRuta => esIntraDistrito
      ? 'Dentro de $distritoOrigen'
      : '$distritoOrigen → $distritoDestino';

  String get precioDisplay {
    if (precioMinSoles != null && precioMaxSoles != null) {
      return 'S/ ${precioMinSoles!.toStringAsFixed(0)} – S/ ${precioMaxSoles!.toStringAsFixed(0)}';
    }
    return 'S/ ${precioSoles.toStringAsFixed(0)}';
  }
}

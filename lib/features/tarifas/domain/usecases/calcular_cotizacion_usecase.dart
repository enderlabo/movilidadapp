import 'package:uuid/uuid.dart';
import '../entities/cotizacion_tarifario.dart';
import '../services/cotizacion_calculator_service.dart';
import '../../../tariff/domain/entities/tarifa_config.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

/// Input parameters for the quotation calculation.
class CalcularCotizacionParams {
  final Vehicle vehiculo;
  final TarifaConfig config;
  final double distanciaKm;
  final double pesoKg;
  final Duration duracionEstimada;
  final String origenDireccion;
  final String destinoDireccion;

  const CalcularCotizacionParams({
    required this.vehiculo,
    required this.config,
    required this.distanciaKm,
    required this.pesoKg,
    required this.duracionEstimada,
    required this.origenDireccion,
    required this.destinoDireccion,
  });
}

/// Use Case: builds a [CotizacionTarifario] from the route and the vehicle.
///
/// SOLID - Single Responsibility: orchestrates (id + timestamp) and delegates
/// the computation to [CotizacionCalculatorService]. Keeps both the formula and
/// the id/timestamp generation out of the presentation layer.
///
/// It does not return `Either<Failure, _>` because the calculation is pure and
/// cannot fail.
class CalcularCotizacionUseCase {
  final CotizacionCalculatorService _calculator;
  final Uuid _uuid;

  CalcularCotizacionUseCase({
    required CotizacionCalculatorService calculator,
    Uuid? uuid,
  })  : _calculator = calculator,
        _uuid = uuid ?? const Uuid();

  CotizacionTarifario call(CalcularCotizacionParams params) {
    return _calculator.calcular(
      id: _uuid.v4(),
      vehiculo: params.vehiculo,
      config: params.config,
      distanciaKm: params.distanciaKm,
      pesoKg: params.pesoKg,
      duracionEstimada: params.duracionEstimada,
      origenDireccion: params.origenDireccion,
      destinoDireccion: params.destinoDireccion,
      generadaEn: DateTime.now(),
    );
  }
}

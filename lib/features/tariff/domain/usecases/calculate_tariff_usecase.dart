import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../entities/tariff_result.dart';
import '../repositories/i_tariff_repository.dart';
import '../services/tariff_calculator_service.dart';
import '../../../routes/domain/entities/route.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

/// Parámetros de entrada del use case.
class CalculateTariffParams {
  final Vehicle vehicle;
  final List<RouteResult> routes;
  final String origenDireccion;
  final String destinoDireccion;
  final TipoCombustible tipoCombustible;

  /// Override de peajes por route ID — cuando la jefa los ajusta manualmente.
  final Map<String, double>? peajesOverridePorRuta;

  const CalculateTariffParams({
    required this.vehicle,
    required this.routes,
    required this.origenDireccion,
    required this.destinoDireccion,
    required this.tipoCombustible,
    this.peajesOverridePorRuta,
  });
}

/// Use Case: Calcula la tarifa completa para todas las rutas.
///
/// SOLID - Single Responsibility: solo orquesta, no calcula directamente.
/// SOLID - Dependency Inversion: depende de interfaces, no de implementaciones.
class CalculateTariffUseCase {
  final ITariffRepository _tariffRepository;
  final IQuotationRepository _quotationRepository;
  final TariffCalculatorService _calculatorService;

  const CalculateTariffUseCase({
    required ITariffRepository tariffRepository,
    required IQuotationRepository quotationRepository,
    required TariffCalculatorService calculatorService,
  })  : _tariffRepository = tariffRepository,
        _quotationRepository = quotationRepository,
        _calculatorService = calculatorService;

  Future<Either<Failure, Quotation>> call(CalculateTariffParams params) async {
    // 1. Fetch fuel price
    final precioResult = await _tariffRepository.getPrecioGalonSoles(
      tipo: params.tipoCombustible,
    );
    if (precioResult.isLeft()) return precioResult.fold(Left.new, (_) => Left(const Failure.unknown()));
    final precioGalon = precioResult.getOrElse(() => 0);

    // 2. Fetch exchange rate
    final tipoCambioResult = await _tariffRepository.getTipoCambio();
    if (tipoCambioResult.isLeft()) return tipoCambioResult.fold(Left.new, (_) => Left(const Failure.unknown()));
    final tipoCambio = tipoCambioResult.getOrElse(() => 3.7);

    // 3. Calcular tarifa para todas las rutas
    final resultados = _calculatorService.calcularParaTodasLasRutas(
      routes: params.routes,
      vehicle: params.vehicle,
      precioGalonSoles: precioGalon,
      tipoCambio: tipoCambio,
      peajesOverridePorRuta: params.peajesOverridePorRuta,
    );

    // 4. Armar cotización y guardar en historial
    final quotation = Quotation(
      id: const Uuid().v4(),
      vehiculoId: params.vehicle.id,
      vehiculoNombre: params.vehicle.nombre,
      origenDireccion: params.origenDireccion,
      destinoDireccion: params.destinoDireccion,
      resultadosPorRuta: resultados,
      precioGalonUsado: precioGalon,
      creadaEn: DateTime.now(),
    );

    return _quotationRepository.saveQuotation(quotation);
  }
}

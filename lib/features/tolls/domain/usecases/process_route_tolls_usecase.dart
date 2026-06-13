import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../entities/toll.dart';
import '../repositories/i_toll_repository.dart';
import '../services/toll_matcher_service.dart';

class ProcessRouteTollsParams {
  final List<TollDetectado> tollsDetectados;  // viene de Maps
  final TipoVehiculo tipoVehiculo;
  final Map<String, double>? overridesJefa;   // correcciones antes de calcular

  const ProcessRouteTollsParams({
    required this.tollsDetectados,
    required this.tipoVehiculo,
    this.overridesJefa,
  });
}

class ProcessRouteTollsResult {
  final List<TollMatchResult> matchResults;
  final List<TollSnapshot> snapshots;
  final double totalSoles;
  final List<TollMatchResult> sinConfirmar; // los que la jefa debe revisar

  const ProcessRouteTollsResult({
    required this.matchResults,
    required this.snapshots,
    required this.totalSoles,
    required this.sinConfirmar,
  });

  bool get requiereRevision => sinConfirmar.isNotEmpty;
}

/// Use Case: procesa los peajes de una ruta completa.
///
/// Flujo:
///   1. Obtiene el catálogo de peajes desde el repositorio.
///   2. Hace matching Maps → catálogo.
///   3. Aplica overrides de la jefa si los hay.
///   4. Registra los peajes nuevos en el catálogo para futuras rutas.
///   5. Retorna snapshots listos para el cálculo de tarifa.
class ProcessRouteTollsUseCase {
  final ITollRepository _tollRepository;
  final TollMatcherService _matcherService;

  const ProcessRouteTollsUseCase({
    required ITollRepository tollRepository,
    required TollMatcherService matcherService,
  })  : _tollRepository = tollRepository,
        _matcherService = matcherService;

  Future<Either<Failure, ProcessRouteTollsResult>> call(
      ProcessRouteTollsParams params) async {
    if (params.tollsDetectados.isEmpty) {
      return Right(ProcessRouteTollsResult(
        matchResults: [],
        snapshots: [],
        totalSoles: 0,
        sinConfirmar: [],
      ));
    }

    // 1. Fetch full toll catalog
    final catalogoResult = await _tollRepository.getAllTolls();
    if (catalogoResult.isLeft()) return catalogoResult.fold(Left.new, (_) => Left(const Failure.unknown()));
    final catalogo = catalogoResult.getOrElse(() => []);

    // 2. Matching
    final matchResults = _matcherService.matchTolls(
      detectados: params.tollsDetectados,
      catalogo: catalogo,
      tipoVehiculo: params.tipoVehiculo,
    );

    // 3. Registrar peajes nuevos en catálogo (sin bloquear el cálculo)
    await _registrarPeajesNuevos(matchResults, params.tipoVehiculo);

    // 4. Construir snapshots con overrides
    final snapshots = _matcherService.buildSnapshots(
      matchResults: matchResults,
      overrides: params.overridesJefa,
    );

    final total = _matcherService.totalPeajesSoles(snapshots);
    final sinConfirmar =
        matchResults.where((r) => r.requiereConfirmacion).toList();

    return Right(ProcessRouteTollsResult(
      matchResults: matchResults,
      snapshots: snapshots,
      totalSoles: total,
      sinConfirmar: sinConfirmar,
    ));
  }

  /// Registra en el catálogo los peajes que Maps detectó pero no estaban.
  /// No bloquea el cálculo — es un side effect asíncrono.
  Future<void> _registrarPeajesNuevos(
    List<TollMatchResult> results,
    TipoVehiculo tipoVehiculo,
  ) async {
    final nuevos = results.where((r) => !r.estaEnCatalogo);

    for (final result in nuevos) {
      final nuevoToll = Toll(
        id: const Uuid().v4(),
        nombre: result.detectado.nombre,
        ubicacion: result.detectado.nombre,
        lat: result.detectado.lat,
        lng: result.detectado.lng,
        tarifasPorTipo: {
          // Solo registra la tarifa del tipo actual si Maps tiene dato
          if (result.detectado.montoEstimadoSoles > 0)
            tipoVehiculo: result.detectado.montoEstimadoSoles,
        },
        fuente: TollFuente.detectadoMaps,
        creadoEn: DateTime.now(),
        actualizadoEn: DateTime.now(),
      );

      // Si falla el registro, no interesa — el cálculo ya tiene el snapshot
      await _tollRepository.createToll(nuevoToll);
    }
  }
}

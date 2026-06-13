import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/toll.dart';
import '../../domain/repositories/i_toll_repository.dart';
import '../../domain/usecases/process_route_tolls_usecase.dart';
import '../../domain/services/toll_matcher_service.dart';

part 'toll_viewmodel.freezed.dart';
part 'toll_viewmodel.g.dart';

@freezed
class TollCatalogState with _$TollCatalogState {
  const factory TollCatalogState.loading() = _Loading;
  const factory TollCatalogState.loaded(List<Toll> tolls) = _Loaded;
  const factory TollCatalogState.error(Failure failure) = _Error;
}

@freezed
class TollMatchingState with _$TollMatchingState {
  const factory TollMatchingState.idle() = _Idle;
  const factory TollMatchingState.processing() = _Processing;
  const factory TollMatchingState.done(ProcessRouteTollsResult result) = _Done;
  const factory TollMatchingState.error(Failure failure) = _MatchError;
}

@riverpod
ITollRepository tollRepository(Ref ref) {
  throw UnimplementedError('Registra en InjectionContainer');
}

@riverpod
ProcessRouteTollsUseCase processRouteTollsUseCase(Ref ref) {
  throw UnimplementedError('Registra en InjectionContainer');
}

@riverpod
class TollCatalogViewModel extends _$TollCatalogViewModel {
  @override
  TollCatalogState build() {
    _loadTolls();
    return const TollCatalogState.loading();
  }

  Future<void> _loadTolls() async {
    final repo = ref.read(tollRepositoryProvider);
    final result = await repo.getAllTolls();
    state = result.fold(
      TollCatalogState.error,
      TollCatalogState.loaded,
    );
  }

  Future<void> actualizarTarifa({
    required String tollId,
    required TipoVehiculo tipoVehiculo,
    required double nuevoMontoSoles,
    String? nota,
  }) async {
    final repo = ref.read(tollRepositoryProvider);
    final result = await repo.updateTollTarifa(
      tollId: tollId,
      tipoVehiculo: tipoVehiculo,
      nuevoMontoSoles: nuevoMontoSoles,
      nota: nota,
    );
    result.fold((_) {}, (_) => _loadTolls());
  }

  Future<void> crearPeajeManual(Toll toll) async {
    final repo = ref.read(tollRepositoryProvider);
    final result = await repo.createToll(
      toll.copyWith(fuente: TollFuente.ingresadoManual),
    );
    result.fold((_) {}, (_) => _loadTolls());
  }

  Future<void> desactivarPeaje(String tollId) async {
    final repo = ref.read(tollRepositoryProvider);
    final result = await repo.deactivateToll(tollId);
    result.fold((_) {}, (_) => _loadTolls());
  }

  Future<void> refresh() => _loadTolls();
}

@riverpod
class TollMatchingViewModel extends _$TollMatchingViewModel {
  @override
  TollMatchingState build() => const TollMatchingState.idle();

  final Map<String, double> _overrides = {};
  Map<String, double> get overrides => Map.unmodifiable(_overrides);
  TipoVehiculo? _tipoVehiculoActual;

  Future<void> procesarPeajesDeRuta({
    required List<TollDetectado> detectados,
    required TipoVehiculo tipoVehiculo,
  }) async {
    _tipoVehiculoActual = tipoVehiculo;
    state = const TollMatchingState.processing();
    final useCase = ref.read(processRouteTollsUseCaseProvider);
    final result = await useCase(ProcessRouteTollsParams(
      tollsDetectados: detectados,
      tipoVehiculo: tipoVehiculo,
      overridesJefa: _overrides.isEmpty ? null : Map.from(_overrides),
    ));
    state = result.fold(
      TollMatchingState.error,
      TollMatchingState.done,
    );
  }

  Future<void> corregirMonto(String tollId, double nuevoMonto) async {
    _overrides[tollId] = nuevoMonto;
    final current = state;
    if (current is _Done) {
      final useCase = ref.read(processRouteTollsUseCaseProvider);
      final recalculado = await useCase(ProcessRouteTollsParams(
        tollsDetectados:
            current.result.matchResults.map((r) => r.detectado).toList(),
        tipoVehiculo: _tipoVehiculoActual ?? TipoVehiculo.camion,
        overridesJefa: Map.from(_overrides),
      ));
      recalculado.fold((_) {}, (r) => state = TollMatchingState.done(r));
    }
  }

  void setTipoVehiculo(TipoVehiculo tipo) => _tipoVehiculoActual = tipo;

  void resetear() {
    _overrides.clear();
    _tipoVehiculoActual = null;
    state = const TollMatchingState.idle();
  }
}

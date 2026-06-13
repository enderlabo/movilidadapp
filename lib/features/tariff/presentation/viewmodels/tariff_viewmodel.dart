import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/tariff_result.dart';
import '../../domain/usecases/calculate_tariff_usecase.dart';
import '../../domain/repositories/i_tariff_repository.dart';
import '../../../routes/domain/entities/route.dart';
import '../../../routes/domain/usecases/get_routes_usecase.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../../core/error/failures.dart';

part 'tariff_viewmodel.freezed.dart';
part 'tariff_viewmodel.g.dart';

@freezed
class TariffState with _$TariffState {
  const factory TariffState.initial() = _Initial;
  const factory TariffState.loadingRoutes() = _LoadingRoutes;
  const factory TariffState.loadingTariff() = _LoadingTariff;
  const factory TariffState.routesLoaded(List<RouteResult> routes) = _RoutesLoaded;
  const factory TariffState.success(Quotation quotation) = _Success;
  const factory TariffState.error(Failure failure) = _Error;
}

@freezed
class TariffInput with _$TariffInput {
  const factory TariffInput({
    Waypoint? origen,
    Waypoint? destino,
    Vehicle? vehiculo,
    @Default(TipoCombustible.diesel) TipoCombustible tipoCombustible,
    @Default({}) Map<String, double> peajesOverride,
  }) = _TariffInput;

  const TariffInput._();

  bool get puedeCalcularRutas => origen != null && destino != null;
  bool get puedeCalcularTarifa => puedeCalcularRutas && vehiculo != null;
}

@riverpod
GetRoutesUseCase getRoutesUseCase(Ref ref) {
  throw UnimplementedError('Registra en InjectionContainer');
}

@riverpod
CalculateTariffUseCase calculateTariffUseCase(Ref ref) {
  throw UnimplementedError('Registra en InjectionContainer');
}

@riverpod
class TariffViewModel extends _$TariffViewModel {
  @override
  TariffState build() => const TariffState.initial();

  TariffInput _input = const TariffInput();
  TariffInput get input => _input;

  List<RouteResult> _rutasCargadas = [];
  List<RouteResult> get rutasCargadas => _rutasCargadas;

  void setOrigen(Waypoint waypoint) => _input = _input.copyWith(origen: waypoint);
  void setDestino(Waypoint waypoint) => _input = _input.copyWith(destino: waypoint);
  void setVehiculo(Vehicle vehicle) => _input = _input.copyWith(vehiculo: vehicle);
  void setTipoCombustible(TipoCombustible tipo) => _input = _input.copyWith(tipoCombustible: tipo);

  void setPeajeOverride(String routeId, double soles) {
    final updated = Map<String, double>.from(_input.peajesOverride)..[routeId] = soles;
    _input = _input.copyWith(peajesOverride: updated);
  }

  Future<void> buscarRutas() async {
    if (!_input.puedeCalcularRutas) return;
    state = const TariffState.loadingRoutes();
    final useCase = ref.read(getRoutesUseCaseProvider);
    final result = await useCase(GetRoutesParams(
      origen: _input.origen!,
      destino: _input.destino!,
    ));
    state = result.fold(
      TariffState.error,
      (routes) {
        _rutasCargadas = routes;
        return TariffState.routesLoaded(routes);
      },
    );
  }

  Future<void> calcularTarifa() async {
    if (!_input.puedeCalcularTarifa || _rutasCargadas.isEmpty) return;
    state = const TariffState.loadingTariff();
    final useCase = ref.read(calculateTariffUseCaseProvider);
    final result = await useCase(CalculateTariffParams(
      vehicle: _input.vehiculo!,
      routes: _rutasCargadas,
      origenDireccion: _input.origen!.direccion,
      destinoDireccion: _input.destino!.direccion,
      tipoCombustible: _input.tipoCombustible,
      peajesOverridePorRuta:
          _input.peajesOverride.isEmpty ? null : _input.peajesOverride,
    ));
    state = result.fold(TariffState.error, TariffState.success);
  }

  void resetear() {
    _input = const TariffInput();
    _rutasCargadas = [];
    state = const TariffState.initial();
  }
}

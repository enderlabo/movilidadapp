import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../routes/domain/entities/route.dart';
import '../../../routes/domain/usecases/get_routes_usecase.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../tarifas/domain/entities/cotizacion_tarifario.dart';
import '../../../../core/error/failures.dart';
import '../../../../injection/injection_container.dart';
import '../../../historial/domain/repositories/i_historial_repository.dart';
import '../../domain/entities/tarifa_config.dart';
import 'tarifa_config_viewmodel.dart';

part 'tariff_viewmodel.freezed.dart';
part 'tariff_viewmodel.g.dart';

@freezed
class TariffState with _$TariffState {
  const factory TariffState.initial() = _Initial;
  const factory TariffState.loadingRoutes() = _LoadingRoutes;
  const factory TariffState.loadingTariff() = _LoadingTariff;
  const factory TariffState.routesLoaded(List<RouteResult> routes) = _RoutesLoaded;
  const factory TariffState.success(CotizacionTarifario cotizacion) = _Success;
  const factory TariffState.sinTarifa(String distritoOrigen, String distritoDestino) = _SinTarifa;
  const factory TariffState.error(Failure failure) = _Error;
}

@freezed
class TariffInput with _$TariffInput {
  const factory TariffInput({
    Waypoint? origen,
    Waypoint? destino,
    Vehicle? vehiculo,
    @Default(0.0) double pesoKg,
    @Default(0) int resetCount,
    @Default(false) bool buscando,
  }) = _TariffInput;

  const TariffInput._();

  bool get puedeCalcularRutas => origen != null && destino != null;
  bool get puedeCalcularTarifa => puedeCalcularRutas && vehiculo != null;
}

// Base de operaciones — punto de salida siempre fijo
const _kOrigenFijo = Waypoint(
  direccion: 'Manuel de la Torre 191, Santa Anita',
  lat: -12.0473,
  lng: -76.9721,
  distrito: 'Santa Anita',
);

// ── Input reactivo — separado del TariffState para no rebuilder en cada keystroke ──

@riverpod
class TariffInputNotifier extends _$TariffInputNotifier {
  @override
  TariffInput build() => const TariffInput(origen: _kOrigenFijo);

  void setOrigen(Waypoint waypoint) => state = state.copyWith(origen: waypoint);
  void setDestino(Waypoint waypoint) => state = state.copyWith(destino: waypoint);
  void setVehiculo(Vehicle vehicle) => state = state.copyWith(vehiculo: vehicle);
  void setPeso(double kg) => state = state.copyWith(pesoKg: kg);
  void reset() => state = TariffInput(
        origen: _kOrigenFijo,
        resetCount: state.resetCount + 1,
      );
}

// ── Providers de casos de uso ──────────────────────────────────────────────────

@riverpod
GetRoutesUseCase getRoutesUseCase(Ref ref) => sl<GetRoutesUseCase>();


// ── ViewModel principal — solo gestiona el estado de la operación ──────────────

@riverpod
class TariffViewModel extends _$TariffViewModel {
  @override
  TariffState build() {
    // Auto-busca rutas en el mapa en cuanto se tienen A y B
    ref.listen<TariffInput>(tariffInputNotifierProvider, (prev, next) {
      final origenCambio = prev?.origen != next.origen;
      final destinoCambio = prev?.destino != next.destino;
      if (next.puedeCalcularRutas && (origenCambio || destinoCambio)) {
        Future.microtask(buscarRutas);
      }
    });
    return const TariffState.initial();
  }

  List<RouteResult> _rutasCargadas = [];
  List<RouteResult> get rutasCargadas => _rutasCargadas;

  Future<void> buscarRutas() async {
    final input = ref.read(tariffInputNotifierProvider);
    if (!input.puedeCalcularRutas) return;
    state = const TariffState.loadingRoutes();
    final useCase = ref.read(getRoutesUseCaseProvider);
    final result = await useCase(GetRoutesParams(
      origen: input.origen!,
      destino: input.destino!,
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
    final input = ref.read(tariffInputNotifierProvider);
    if (!input.puedeCalcularTarifa) return;

    if (_rutasCargadas.isEmpty) await buscarRutas();

    state = const TariffState.loadingTariff();

    final origen = input.origen!;
    final destino = input.destino!;
    final vehiculo = input.vehiculo!;

    final rutaPrincipal = _rutasCargadas.isNotEmpty ? _rutasCargadas.first : null;
    final distanciaKm = rutaPrincipal?.distanciaKm ?? 0;

    final config = ref.read(tarifaConfigNotifierProvider).valueOrNull ??
        TarifaConfig.defaults;

    final tarifaPorKm = vehiculo.categoria == CategoriaVehiculo.pequeno
        ? config.tarifaPequeno
        : config.tarifaGrande;

    final pesoKg = input.pesoKg;
    final costoKilometraje = tarifaPorKm * distanciaKm * 2; // × 2: entrega y recojo
    final costoTiempo = costoKilometraje * config.factorTiempo;
    final costoPeso = pesoKg * config.tarifaPorKg;
    final precioTotal = costoKilometraje + costoTiempo + costoPeso;

    final cotizacion = CotizacionTarifario(
      id: const Uuid().v4(),
      categoria: vehiculo.categoria,
      vehiculoNombre: vehiculo.nombre,
      origenDireccion: origen.direccion,
      destinoDireccion: destino.direccion,
      tarifaPorKm: tarifaPorKm,
      distanciaKm: distanciaKm,
      costoKilometraje: costoKilometraje,
      costoTiempo: costoTiempo,
      pesoKg: pesoKg,
      costoPeso: costoPeso,
      precioTotal: precioTotal,
      duracionEstimada: rutaPrincipal?.duracionEstimada ?? Duration.zero,
      generadaEn: DateTime.now(),
    );

    state = TariffState.success(cotizacion);
  }

  Future<void> guardar() async {
    final cotizacion = state.whenOrNull(success: (c) => c);
    if (cotizacion == null) return;
    await sl<IHistorialRepository>().guardar(cotizacion);
    resetear();
  }

  void olvidar() => resetear();

  void resetear() {
    _rutasCargadas = [];
    state = const TariffState.initial();
    ref.read(tariffInputNotifierProvider.notifier).reset();
  }
}

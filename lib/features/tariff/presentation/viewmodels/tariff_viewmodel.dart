import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../routes/domain/entities/route.dart';
import '../../../routes/domain/usecases/get_routes_usecase.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/entities/vehicle_recommendation.dart';
import '../../../vehicles/domain/services/vehicle_selection_service.dart';
import '../../../tarifas/domain/entities/cotizacion_tarifario.dart';
import '../../../tarifas/domain/usecases/calcular_cotizacion_usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../../injection/injection_container.dart';
import '../../../historial/presentation/viewmodels/historial_viewmodel.dart';
import 'tarifa_config_viewmodel.dart';

part 'tariff_viewmodel.freezed.dart';
part 'tariff_viewmodel.g.dart';

@freezed
sealed class TariffState with _$TariffState {
  const factory TariffState.initial() = _Initial;
  const factory TariffState.loadingRoutes() = _LoadingRoutes;
  const factory TariffState.loadingTariff() = _LoadingTariff;
  const factory TariffState.routesLoaded(List<RouteResult> routes) = _RoutesLoaded;
  const factory TariffState.success(CotizacionTarifario cotizacion) = _Success;
  const factory TariffState.sinTarifa(String distritoOrigen, String distritoDestino) = _SinTarifa;
  const factory TariffState.error(Failure failure) = _Error;
}

@freezed
abstract class TariffInput with _$TariffInput {
  const factory TariffInput({
    Waypoint? origen,
    Waypoint? destino,
    Vehicle? vehiculo,
    @Default(0.0) double pesoKg,
    @Default(0) int resetCount,
    @Default(false) bool buscando,
    VehicleRecommendation? recomendacion,
    /// true cuando el usuario eligió un vehículo manualmente en el dropdown.
    /// Evita que la recomendación automática sobreescriba su elección.
    @Default(false) bool seleccionManual,
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
  static const _selectionService = VehicleSelectionService();

  @override
  TariffInput build() => const TariffInput(origen: _kOrigenFijo);

  void setOrigen(Waypoint waypoint) => state = state.copyWith(origen: waypoint);

  void setDestino(Waypoint waypoint) {
    final rec = _recomendar(waypoint.distrito, state.pesoKg);
    // DEBUG: eliminar cuando esté validado
    debugPrint('[Destino] distrito="${waypoint.distrito}" → rec=${rec?.placaRecomendada}/${rec?.zona.name}');
    state = state.copyWith(destino: waypoint, recomendacion: rec);
  }

  /// El usuario eligió un vehículo en el dropdown — bloquea el auto-switch.
  void setVehiculo(Vehicle vehicle) =>
      state = state.copyWith(vehiculo: vehicle, seleccionManual: true);

  /// Auto-selección por recomendación — no bloquea futuros cambios automáticos.
  void autoSelectVehiculo(Vehicle vehicle) =>
      state = state.copyWith(vehiculo: vehicle, seleccionManual: false);

  void setPeso(double kg) {
    final rec = _recomendar(state.destino?.distrito, kg);
    state = state.copyWith(pesoKg: kg, recomendacion: rec);
  }

  /// Llamado por TariffViewModel cuando Maps devuelve las rutas.
  /// Actualiza la recomendación usando el resumen de la ruta principal,
  /// lo que permite detectar Vía de Evitamiento / Panamericanas.
  void actualizarPorRutas(List<RouteResult> rutas) {
    final distrito = state.destino?.distrito;
    if (distrito == null || distrito.isEmpty) return;
    final resumenRuta = rutas.isNotEmpty ? rutas.first.resumenRuta : null;
    final rec = _selectionService.recomendarConRuta(
      distritoDestino: distrito,
      pesoKg: state.pesoKg,
      resumenRuta: resumenRuta,
    );
    state = state.copyWith(recomendacion: rec);
  }

  void reset() => state = TariffInput(
        origen: _kOrigenFijo,
        resetCount: state.resetCount + 1,
      );

  VehicleRecommendation? _recomendar(String? distrito, double pesoKg) {
    if (distrito == null || distrito.isEmpty) return null;
    return _selectionService.recomendar(
      distritoDestino: distrito,
      pesoKg: pesoKg,
    );
  }
}

// ── Providers de casos de uso ──────────────────────────────────────────────────

@riverpod
GetRoutesUseCase getRoutesUseCase(Ref ref) => sl<GetRoutesUseCase>();

/// Manual provider (no codegen) for the quotation calculation use case.
final calcularCotizacionUseCaseProvider = Provider<CalcularCotizacionUseCase>(
  (ref) => sl<CalcularCotizacionUseCase>(),
);


// ── ViewModel principal — solo gestiona el estado de la operación ──────────────

@riverpod
class TariffViewModel extends _$TariffViewModel {
  @override
  TariffState build() {
    // Auto-busca rutas en el mapa en cuanto se tienen A y B
    ref.listen<TariffInput>(tariffInputProvider, (prev, next) {
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
    final input = ref.read(tariffInputProvider);
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
        // Actualiza recomendación con el resumen de ruta real de Maps
        // (permite detectar Vía de Evitamiento, Panamericanas, etc.)
        ref
            .read(tariffInputProvider.notifier)
            .actualizarPorRutas(routes);
        return TariffState.routesLoaded(routes);
      },
    );
  }

  Future<void> calcularTarifa() async {
    final input = ref.read(tariffInputProvider);
    if (!input.puedeCalcularTarifa) return;

    if (_rutasCargadas.isEmpty) await buscarRutas();

    state = const TariffState.loadingTariff();

    final origen = input.origen!;
    final destino = input.destino!;
    final vehiculo = input.vehiculo!;

    final rutaPrincipal = _rutasCargadas.isNotEmpty ? _rutasCargadas.first : null;

    final config = await ref.read(tarifaConfigProvider.future);

    final cotizacion = ref.read(calcularCotizacionUseCaseProvider)(
      CalcularCotizacionParams(
        vehiculo: vehiculo,
        config: config,
        distanciaKm: rutaPrincipal?.distanciaKm ?? 0,
        pesoKg: input.pesoKg,
        duracionEstimada: rutaPrincipal?.duracionEstimada ?? Duration.zero,
        origenDireccion: origen.direccion,
        destinoDireccion: destino.direccion,
      ),
    );

    state = TariffState.success(cotizacion);
  }

  Future<void> guardar() async {
    final cotizacion = state.whenOrNull(success: (c) => c);
    if (cotizacion == null) return;
    await ref.read(historialRepositoryProvider).guardar(cotizacion);
    resetear();
  }

  void olvidar() => resetear();

  void resetear() {
    _rutasCargadas = [];
    state = const TariffState.initial();
    ref.read(tariffInputProvider.notifier).reset();
  }
}

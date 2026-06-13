import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../core/network/local_cache.dart';
import '../features/tariff/domain/services/tariff_calculator_service.dart';
import '../features/tariff/domain/usecases/calculate_tariff_usecase.dart';
import '../features/tariff/domain/repositories/i_tariff_repository.dart';
import '../features/tariff/data/repositories/tariff_repository_impl.dart';
import '../features/tariff/data/repositories/quotation_repository_impl.dart';
import '../features/routes/domain/usecases/get_routes_usecase.dart';
import '../features/routes/domain/repositories/i_route_repository.dart';
import '../features/routes/data/repositories/route_repository_impl.dart';
import '../features/vehicles/domain/repositories/i_vehicle_repository.dart';
import '../features/vehicles/data/repositories/vehicle_repository_impl.dart';
import '../features/tolls/domain/repositories/i_toll_repository.dart';
import '../features/tolls/domain/services/toll_matcher_service.dart';
import '../features/tolls/domain/usecases/process_route_tolls_usecase.dart';
import '../features/tolls/data/repositories/toll_repository_impl.dart';

final sl = GetIt.instance;

/// Dependency injection container.
///
/// Registration order: External → Infrastructure → Data → Domain → Use Cases.
/// Domain never imports implementations directly — only interfaces.
abstract final class InjectionContainer {
  static Future<void> init() async {
    // ── External ──────────────────────────────────────────────────────────────
    // Firebase must be initialized before this (see main.dart).
    sl.registerLazySingleton(() => FirebaseFirestore.instance);

    sl.registerLazySingleton(() => Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )));

    // ── Infrastructure ────────────────────────────────────────────────────────
    sl.registerLazySingleton(() => LocalCache());

    // ── Domain services (pure, no I/O) ────────────────────────────────────────
    sl.registerLazySingleton(() => const TariffCalculatorService());
    sl.registerLazySingleton(() => const TollMatcherService());

    // ── Repositories ──────────────────────────────────────────────────────────
    sl.registerLazySingleton<IVehicleRepository>(
      () => VehicleRepositoryImpl(firestore: sl()),
    );

    sl.registerLazySingleton<ITollRepository>(
      () => TollRepositoryImpl(firestore: sl()),
    );

    sl.registerLazySingleton<ITariffRepository>(
      () => TariffRepositoryImpl(dio: sl(), cache: sl()),
    );

    sl.registerLazySingleton<IQuotationRepository>(
      () => QuotationRepositoryImpl(firestore: sl(), cache: sl()),
    );

    sl.registerLazySingleton<IRouteRepository>(
      () => RouteRepositoryImpl(dio: sl()),
    );

    // ── Use Cases ─────────────────────────────────────────────────────────────
    sl.registerLazySingleton(
      () => GetRoutesUseCase(sl<IRouteRepository>()),
    );

    sl.registerLazySingleton(
      () => ProcessRouteTollsUseCase(
        tollRepository: sl<ITollRepository>(),
        matcherService: sl<TollMatcherService>(),
      ),
    );

    sl.registerLazySingleton(
      () => CalculateTariffUseCase(
        tariffRepository: sl<ITariffRepository>(),
        quotationRepository: sl<IQuotationRepository>(),
        calculatorService: sl<TariffCalculatorService>(),
      ),
    );
  }
}

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/local_cache.dart';
import '../../domain/repositories/i_tariff_repository.dart';

// Cache TTL: fuel price and exchange rate refreshed once per day.
const _cacheTtlHours = 24;

class TariffRepositoryImpl implements ITariffRepository {
  final Dio _dio;
  final LocalCache _cache;

  const TariffRepositoryImpl({required Dio dio, required LocalCache cache})
      : _dio = dio,
        _cache = cache;

  // ── Fuel price (OSINERGMIN) ───────────────────────────────────────────────

  @override
  Future<Either<Failure, double>> getPrecioGalonSoles({
    required TipoCombustible tipo,
  }) async {
    final cacheKey = 'fuel_price_${tipo.name}';
    final metaKey = 'fuel_price_ts_${tipo.name}';

    // Return cached value if still fresh.
    final cachedTs = await _cache.getString(metaKey);
    if (cachedTs != null) {
      final saved = DateTime.tryParse(cachedTs);
      if (saved != null &&
          DateTime.now().difference(saved).inHours < _cacheTtlHours) {
        final raw = await _cache.getString(cacheKey);
        if (raw != null) return Right(double.parse(raw));
      }
    }

    // TODO: Replace with real OSINERGMIN SCOP API scraping.
    // The API endpoint requires institutional credentials.
    // For now return representative Lima prices (June 2025).
    final fallback = _precioFallback(tipo);
    await _cache.setString(cacheKey, fallback.toString());
    await _cache.setString(metaKey, DateTime.now().toIso8601String());
    return Right(fallback);
  }

  @override
  Future<Either<Failure, Unit>> cachePrecioGalon({
    required TipoCombustible tipo,
    required double precioSoles,
    required DateTime actualizadoEn,
  }) async {
    await _cache.setString('fuel_price_${tipo.name}', precioSoles.toString());
    await _cache.setString(
        'fuel_price_ts_${tipo.name}', actualizadoEn.toIso8601String());
    return const Right(unit);
  }

  // ── Exchange rate (SBS via apis.net.pe) ──────────────────────────────────

  @override
  Future<Either<Failure, double>> getTipoCambio() async {
    const cacheKey = 'tipo_cambio';
    const metaKey = 'tipo_cambio_ts';

    final cachedTs = await _cache.getString(metaKey);
    if (cachedTs != null) {
      final saved = DateTime.tryParse(cachedTs);
      if (saved != null &&
          DateTime.now().difference(saved).inHours < _cacheTtlHours) {
        final raw = await _cache.getString(cacheKey);
        if (raw != null) return Right(double.parse(raw));
      }
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.apis.net.pe/v2/tipo-cambio',
        options: Options(
          receiveTimeout: const Duration(seconds: 8),
          headers: {'Accept': 'application/json'},
        ),
      );
      final data = response.data!;
      // Use "venta" rate — how many PEN per 1 USD when company sells USD.
      final venta = double.parse(data['venta'].toString());
      await _cache.setString(cacheKey, venta.toString());
      await _cache.setString(metaKey, DateTime.now().toIso8601String());
      return Right(venta);
    } on DioException catch (e) {
      // Serve stale cache rather than fail completely.
      final stale = await _cache.getString(cacheKey);
      if (stale != null) return Right(double.parse(stale));
      return Left(Failure.network(
          message: 'No se pudo obtener tipo de cambio: ${e.message}'));
    } catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  // Approximate Lima retail prices (June 2025). Update once OSINERGMIN API is integrated.
  double _precioFallback(TipoCombustible tipo) => switch (tipo) {
        TipoCombustible.diesel => 14.50,
        TipoCombustible.gasolina90 => 15.20,
        TipoCombustible.gasolina95 => 16.80,
        TipoCombustible.gasolina97 => 18.10,
      };
}

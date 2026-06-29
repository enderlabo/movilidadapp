import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Jerarquía de fallos del dominio.
/// Nunca se lanzan excepciones fuera de la capa de datos — todo es [Either<Failure, T>].
@freezed
sealed class Failure with _$Failure {
  // Red
  const factory Failure.network({
    @Default('Sin conexión a internet') String message,
  }) = NetworkFailure;

  // Google Maps
  const factory Failure.mapsApi({
    required String message,
    int? statusCode,
  }) = MapsApiFailure;

  // Firebase / Firestore
  const factory Failure.database({
    @Default('Error en base de datos') String message,
  }) = DatabaseFailure;

  // Cache local (Hive)
  const factory Failure.cache({
    @Default('Error en caché local') String message,
  }) = CacheFailure;

  // OSINERGMIN scraping
  const factory Failure.fuelPrice({
    @Default('No se pudo obtener precio de combustible') String message,
  }) = FuelPriceFailure;

  // Validación de datos de entrada
  const factory Failure.validation({
    required String message,
  }) = ValidationFailure;

  // Servidor externo
  const factory Failure.server({
    @Default('Error del servidor') String message,
    int? statusCode,
  }) = ServerFailure;

  const factory Failure.unknown({
    @Default('Error inesperado') String message,
  }) = UnknownFailure;
}

extension FailureX on Failure {
  String get userMessage => when(
        network: (msg) => msg,
        mapsApi: (msg, _) => 'Google Maps: $msg',
        database: (msg) => msg,
        cache: (msg) => msg,
        fuelPrice: (msg) => msg,
        validation: (msg) => msg,
        server: (msg, _) => msg,
        unknown: (msg) => msg,
      );
}

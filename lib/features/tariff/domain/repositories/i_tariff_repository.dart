import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tariff_result.dart';

abstract interface class ITariffRepository {
  /// Precio actual del galón de diesel/gasolina desde caché OSINERGMIN.
  /// Se actualiza una vez al día vía job en background.
  Future<Either<Failure, double>> getPrecioGalonSoles({
    required TipoCombustible tipo,
  });

  /// Guarda el precio actualizado en caché local (llamado por el job diario).
  Future<Either<Failure, Unit>> cachePrecioGalon({
    required TipoCombustible tipo,
    required double precioSoles,
    required DateTime actualizadoEn,
  });

  /// Tipo de cambio PEN → USD desde SBS (o caché si offline).
  Future<Either<Failure, double>> getTipoCambio();
}

abstract interface class IQuotationRepository {
  /// Guarda una cotización en Firestore + caché Hive.
  Future<Either<Failure, Quotation>> saveQuotation(Quotation quotation);

  /// Historial de cotizaciones (con soporte offline desde Hive).
  Future<Either<Failure, List<Quotation>>> getHistorial({
    int limit = 50,
    DateTime? desde,
  });

  /// Cotización individual por ID.
  Future<Either<Failure, Quotation>> getQuotation(String id);

  /// Elimina del historial.
  Future<Either<Failure, Unit>> deleteQuotation(String id);

  /// Stream para actualización en tiempo real.
  Stream<Either<Failure, List<Quotation>>> watchHistorial();
}

enum TipoCombustible {
  diesel,
  gasolina90,
  gasolina95,
  gasolina97;

  String get displayName => switch (this) {
        TipoCombustible.diesel => 'Diesel B5',
        TipoCombustible.gasolina90 => 'Gasolina 90',
        TipoCombustible.gasolina95 => 'Gasolina 95',
        TipoCombustible.gasolina97 => 'Gasolina 97',
      };
}

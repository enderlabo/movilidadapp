import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/toll.dart';

abstract interface class ITollRepository {
  /// Busca peajes en el catálogo cercanos a coordenadas dadas.
  /// Usado para matchear los peajes detectados por Maps con el catálogo.
  Future<Either<Failure, List<Toll>>> findTollsNearby({
    required double lat,
    required double lng,
    double radiusKm = 0.5, // radio de búsqueda para el match
  });

  /// Retorna todo el catálogo de peajes activos.
  Future<Either<Failure, List<Toll>>> getAllTolls();

  /// Crea un nuevo peaje en el catálogo.
  Future<Either<Failure, Toll>> createToll(Toll toll);

  /// Actualiza el monto de un peaje — la jefa corrige el precio.
  /// Registra automáticamente quién y cuándo actualizó.
  Future<Either<Failure, Toll>> updateTollTarifa({
    required String tollId,
    required TipoVehiculo tipoVehiculo,
    required double nuevoMontoSoles,
    String? nota,
  });

  /// Desactiva un peaje del catálogo (fue eliminado en la realidad).
  Future<Either<Failure, Unit>> deactivateToll(String tollId);

  /// Stream para actualizaciones en tiempo real desde Firestore.
  Stream<Either<Failure, List<Toll>>> watchTolls();
}

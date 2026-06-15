import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/tarifa_zona.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

abstract interface class ITarifaZonaRepository {
  Stream<Either<Failure, List<TarifaZona>>> watchTarifas();
  Future<Either<Failure, List<TarifaZona>>> getTarifas();
  Future<Either<Failure, TarifaZona?>> buscarTarifa({
    required String distritoOrigen,
    required String distritoDestino,
    required CategoriaVehiculo categoria,
  });
  Future<Either<Failure, TarifaZona>> saveTarifa(TarifaZona tarifa);
  Future<Either<Failure, Unit>> deleteTarifa(String id);
}

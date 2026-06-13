import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vehicle.dart';

/// Contrato que la capa de datos debe implementar.
/// El dominio depende de esta abstracción, nunca de la implementación.
abstract interface class IVehicleRepository {
  /// Retorna todos los vehículos activos.
  Future<Either<Failure, List<Vehicle>>> getVehiculos();

  /// Retorna un vehículo por ID.
  Future<Either<Failure, Vehicle>> getVehiculo(String id);

  /// Crea o actualiza un vehículo.
  Future<Either<Failure, Vehicle>> saveVehiculo(Vehicle vehicle);

  /// Desactiva un vehículo (soft delete).
  Future<Either<Failure, Unit>> deleteVehiculo(String id);

  /// Stream para actualizaciones en tiempo real desde Firestore.
  Stream<Either<Failure, List<Vehicle>>> watchVehiculos();
}

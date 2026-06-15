import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../tarifas/domain/entities/cotizacion_tarifario.dart';

abstract interface class IHistorialRepository {
  Stream<Either<Failure, List<CotizacionTarifario>>> watchHistorial();
  Future<Either<Failure, Unit>> guardar(CotizacionTarifario cotizacion);
  Future<Either<Failure, Unit>> eliminar(String id);
}

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/zona_tarifaria.dart';

abstract interface class IZonaTarifariaRepository {
  Stream<Either<Failure, List<ZonaTarifaria>>> watchZonas();
  Future<Either<Failure, List<ZonaTarifaria>>> getZonas();
  Future<Either<Failure, ZonaTarifaria>> saveZona(ZonaTarifaria zona);
  Future<Either<Failure, Unit>> deleteZona(String id);
  Future<Either<Failure, Unit>> seedZonasDefault();
}

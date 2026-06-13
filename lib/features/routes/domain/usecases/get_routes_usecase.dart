import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/route.dart';
import '../repositories/i_route_repository.dart';

class GetRoutesParams {
  final Waypoint origen;
  final Waypoint destino;

  const GetRoutesParams({required this.origen, required this.destino});
}

class GetRoutesUseCase {
  final IRouteRepository _repository;

  const GetRoutesUseCase(this._repository);

  Future<Either<Failure, List<RouteResult>>> call(
      GetRoutesParams params) async {
    if (params.origen.lat == params.destino.lat &&
        params.origen.lng == params.destino.lng) {
      return const Left(
          Failure.validation(message: 'Origen y destino no pueden ser iguales'));
    }

    final result = await _repository.getRoutes(
      origen: params.origen,
      destino: params.destino,
    );

    return result.fold(
      Left.new,
      (routes) {
        if (routes.isEmpty) {
          return const Left(
              Failure.mapsApi(message: 'No se encontraron rutas disponibles'));
        }
        // Ordenar: primero la más rápida, luego alternativas
        final sorted = [...routes]
          ..sort((a, b) => a.duracionEstimada.compareTo(b.duracionEstimada));
        return Right(sorted);
      },
    );
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/route.dart';

abstract interface class IRouteRepository {
  /// Obtiene ≥2 rutas entre origen y destino desde Google Maps.
  /// En web usa JS Interop; en mobile/desktop usa el SDK nativo.
  Future<Either<Failure, List<RouteResult>>> getRoutes({
    required Waypoint origen,
    required Waypoint destino,
  });

  /// Geocodifica una dirección de texto a coordenadas.
  Future<Either<Failure, Waypoint>> geocodeAddress(String address);

  /// Sugerencias de autocompletado para el buscador de direcciones.
  Future<Either<Failure, List<String>>> autocompleteAddress(String input);
}

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/route.dart';
import '../../domain/repositories/i_route_repository.dart';

class RouteRepositoryImpl implements IRouteRepository {
  final Dio _dio;

  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  RouteRepositoryImpl({required Dio dio}) : _dio = dio;

  /// Centraliza el manejo de errores de las llamadas a Google Maps:
  /// conexión → [Failure.network], error HTTP → [Failure.mapsApi], resto →
  /// [Failure.server]. El [body] devuelve el [Either] con los casos de dominio
  /// (p. ej. "sin rutas") y solo necesita lanzar para los fallos de transporte.
  Future<Either<Failure, T>> _guardMaps<T>(
    Future<Either<Failure, T>> Function() body,
  ) async {
    try {
      return await body();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return const Left(Failure.network());
      }
      return Left(Failure.mapsApi(
        message: e.response?.data?.toString() ?? e.message ?? 'Unknown',
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  // ── Routes (Google Maps Routes API v2) ───────────────────────────────────

  @override
  Future<Either<Failure, List<RouteResult>>> getRoutes({
    required Waypoint origen,
    required Waypoint destino,
  }) {
    return _guardMaps(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://routes.googleapis.com/directions/v2:computeRoutes',
        options: Options(headers: {
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'routes.duration,routes.distanceMeters,routes.polyline,'
              'routes.description,routes.travelAdvisory,routes.localizedValues',
          'Content-Type': 'application/json',
        }),
        data: {
          'origin': {
            'location': {
              'latLng': {'latitude': origen.lat, 'longitude': origen.lng}
            }
          },
          'destination': {
            'location': {
              'latLng': {'latitude': destino.lat, 'longitude': destino.lng}
            }
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
          'computeAlternativeRoutes': true,
          'extraComputations': ['TOLLS'],
          'languageCode': 'es-PE',
          'units': 'METRIC',
        },
      );

      final routes = (response.data!['routes'] as List?) ?? [];
      if (routes.isEmpty) {
        return const Left(Failure.mapsApi(message: 'No routes found'));
      }

      final results = routes
          .asMap()
          .entries
          .map((e) => _parseRoute(e.value as Map<String, dynamic>, e.key))
          .toList();
      return Right(results);
    });
  }

  // ── Geocoding ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Waypoint>> geocodeAddress(String address) {
    return _guardMaps(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'address': address,
          'key': _apiKey,
          'region': 'pe',
          'language': 'es',
        },
      );

      final data = response.data!;
      if (data['status'] != 'OK') {
        return Left(Failure.mapsApi(
            message: 'Geocoding failed: ${data["status"]}'));
      }

      final result = data['results'][0] as Map<String, dynamic>;
      final location = result['geometry']['location'];
      final formatted = result['formatted_address'] as String;
      final distrito = _extractDistrito(result);
      // DEBUG: eliminar cuando esté validado
      debugPrint('[Geocode] "$formatted" → distrito="$distrito"');
      return Right(Waypoint(
        direccion: formatted,
        lat: (location['lat'] as num).toDouble(),
        lng: (location['lng'] as num).toDouble(),
        distrito: distrito,
      ));
    });
  }

  // ── Places Autocomplete ───────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<String>>> autocompleteAddress(String input) {
    return _guardMaps(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': _apiKey,
          'components': 'country:pe',
          'language': 'es',
          'types': 'geocode',
        },
      );

      final data = response.data!;
      if (data['status'] == 'ZERO_RESULTS') return const Right([]);
      if (data['status'] != 'OK') {
        final status = data['status'] as String;
        final hint = switch (status) {
          'REQUEST_DENIED' =>
            'REQUEST_DENIED — verifica que "Places API" esté habilitada en Google Cloud Console y que la API key no tenga restricciones de plataforma',
          'OVER_DAILY_LIMIT' => 'OVER_DAILY_LIMIT — cuota diaria agotada o billing no configurado',
          'OVER_QUERY_LIMIT' => 'OVER_QUERY_LIMIT — demasiadas solicitudes por segundo',
          'INVALID_REQUEST'  => 'INVALID_REQUEST — parámetro inválido',
          _ => status,
        };
        return Left(Failure.mapsApi(message: hint));
      }

      final predictions = (data['predictions'] as List)
          .map((p) => p['description'] as String)
          .toList();
      return Right(predictions);
    });
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  String? _extractDistrito(Map<String, dynamic> result) {
    final components = result['address_components'] as List? ?? [];
    // DEBUG: log all components to understand Google's hierarchy for Lima
    for (final comp in components) {
      final types = (comp['types'] as List? ?? []).cast<String>();
      debugPrint('[Geocode-comp] ${comp['long_name']} → $types');
    }
    // Orden de prioridad para distritos de Lima, Perú:
    // Google retorna el distrito como locality, administrative_area_level_3
    // o sublocality_level_1 dependiendo del tipo de lugar.
    const prioridad = [
      'administrative_area_level_3',
      'sublocality_level_1',
      'locality',
      'sublocality',
    ];
    for (final tipo in prioridad) {
      for (final comp in components) {
        final types = (comp['types'] as List? ?? []).cast<String>();
        if (types.contains(tipo)) {
          // Excluye "Lima" como ciudad (administrative_area_level_2)
          final nombre = comp['long_name'] as String? ?? '';
          if (nombre.toLowerCase() != 'lima') return nombre;
        }
      }
    }
    return null;
  }

  RouteResult _parseRoute(Map<String, dynamic> route, int index) {
    final distanceMeters = (route['distanceMeters'] as num?)?.toInt() ?? 0;
    final durationStr = route['duration'] as String? ?? '0s';
    final seconds = int.tryParse(durationStr.replaceAll('s', '')) ?? 0;

    final tolls = _extractTollsSoles(route);
    final encoded =
        (route['polyline'] as Map?)?['encodedPolyline'] as String? ?? '';
    final polyline = _decodePolyline(encoded);
    debugPrint(
        '[Routes] ruta[$index] distancia=${distanceMeters}m '
        'encoded.length=${encoded.length} puntos=${polyline.length} '
        'descripcion="${route['description']}"');

    return RouteResult(
      id: const Uuid().v4(),
      etiqueta: index == 0 ? 'Ruta más rápida' : 'Ruta alternativa $index',
      distanciaKm: distanceMeters / 1000.0,
      duracionEstimada: Duration(seconds: seconds),
      peajesEstimadosSoles: tolls,
      tienePeajesConfiables: tolls > 0,
      polilinea: polyline,
      resumenRuta: route['description'] as String? ?? '',
    );
  }

  double _extractTollsSoles(Map<String, dynamic> route) {
    try {
      final advisory = route['travelAdvisory'] as Map<String, dynamic>?;
      final tollInfo = advisory?['tollInfo'] as Map<String, dynamic>?;
      final prices = tollInfo?['estimatedPrice'] as List?;
      if (prices == null || prices.isEmpty) return 0;
      // Find PEN price; fallback to USD * approx exchange rate.
      for (final price in prices) {
        final p = price as Map<String, dynamic>;
        if (p['currencyCode'] == 'PEN') {
          final units = int.tryParse(p['units']?.toString() ?? '0') ?? 0;
          final nanos = (p['nanos'] as num?)?.toInt() ?? 0;
          return units + nanos / 1e9;
        }
      }
    } catch (_) {}
    return 0;
  }

  /// Decodes a Google encoded polyline into a list of lat/lng points.
  List<PuntoRuta> _decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];
    final result = <PuntoRuta>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, res = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        res |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((res & 1) != 0) ? ~(res >> 1) : (res >> 1);

      shift = 0;
      res = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        res |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((res & 1) != 0) ? ~(res >> 1) : (res >> 1);

      result.add(PuntoRuta(lat: lat / 1e5, lng: lng / 1e5));
    }
    return result;
  }
}

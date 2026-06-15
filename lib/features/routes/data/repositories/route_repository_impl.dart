import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/route.dart';
import '../../domain/repositories/i_route_repository.dart';

class RouteRepositoryImpl implements IRouteRepository {
  final Dio _dio;

  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  RouteRepositoryImpl({required Dio dio}) : _dio = dio;

  // ── Routes (Google Maps Routes API v2) ───────────────────────────────────

  @override
  Future<Either<Failure, List<RouteResult>>> getRoutes({
    required Waypoint origen,
    required Waypoint destino,
  }) async {
    try {
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
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return const Left(Failure.network());
      }
      return Left(Failure.mapsApi(
          message: e.response?.data.toString() ?? e.message ?? 'Unknown',
          statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  // ── Geocoding ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Waypoint>> geocodeAddress(String address) async {
    try {
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
      return Right(Waypoint(
        direccion: formatted,
        lat: (location['lat'] as num).toDouble(),
        lng: (location['lng'] as num).toDouble(),
        distrito: distrito,
      ));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        return const Left(Failure.network());
      }
      return Left(Failure.mapsApi(message: e.message ?? 'Geocoding error'));
    } catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  // ── Places Autocomplete ───────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<String>>> autocompleteAddress(
      String input) async {
    try {
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
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        return const Left(Failure.network());
      }
      return Left(Failure.mapsApi(message: e.message ?? 'Autocomplete error'));
    } catch (e) {
      return Left(Failure.server(message: e.toString()));
    }
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  String? _extractDistrito(Map<String, dynamic> result) {
    final components = result['address_components'] as List? ?? [];
    for (final comp in components) {
      final types = (comp['types'] as List? ?? []).cast<String>();
      if (types.contains('administrative_area_level_3') ||
          types.contains('sublocality_level_1')) {
        return comp['long_name'] as String?;
      }
    }
    // fallback to sublocality
    for (final comp in components) {
      final types = (comp['types'] as List? ?? []).cast<String>();
      if (types.contains('sublocality')) {
        return comp['long_name'] as String?;
      }
    }
    return null;
  }

  RouteResult _parseRoute(Map<String, dynamic> route, int index) {
    final distanceMeters = (route['distanceMeters'] as num?)?.toInt() ?? 0;
    final durationStr = route['duration'] as String? ?? '0s';
    final seconds = int.tryParse(durationStr.replaceAll('s', '')) ?? 0;

    final tolls = _extractTollsSoles(route);
    final polyline = _decodePolyline(
        (route['polyline'] as Map?)?['encodedPolyline'] as String? ?? '');

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

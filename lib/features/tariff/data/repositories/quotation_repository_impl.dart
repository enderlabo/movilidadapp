import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/local_cache.dart';
import '../../domain/entities/tariff_result.dart';
import '../../domain/repositories/i_tariff_repository.dart';

class QuotationRepositoryImpl implements IQuotationRepository {
  final FirebaseFirestore _firestore;
  final LocalCache _cache;

  static const _collection = 'quotations';
  static const _cacheKey = 'quotations_list';

  const QuotationRepositoryImpl({
    required FirebaseFirestore firestore,
    required LocalCache cache,
  })  : _firestore = firestore,
        _cache = cache;

  @override
  Future<Either<Failure, Quotation>> saveQuotation(Quotation quotation) async {
    try {
      final data = _quotationToMap(quotation);
      await _firestore.collection(_collection).doc(quotation.id).set(data);
      await _appendToLocalCache(quotation);
      return Right(quotation);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Quotation>>> getHistorial({
    int limit = 50,
    DateTime? desde,
  }) async {
    try {
      var query = _firestore
          .collection(_collection)
          .orderBy('creadaEn', descending: true)
          .limit(limit);
      if (desde != null) {
        query = query.where('creadaEn',
            isGreaterThanOrEqualTo: desde.toIso8601String());
      }
      final snap = await query.get();
      return Right(snap.docs.map(_fromDoc).toList());
    } catch (_) {
      // Offline fallback: serve from local cache.
      return _historialFromCache(limit);
    }
  }

  @override
  Future<Either<Failure, Quotation>> getQuotation(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        return const Left(Failure.database(message: 'Quotation not found'));
      }
      return Right(_fromDoc(doc));
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteQuotation(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      await _removeFromLocalCache(id);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Quotation>>> watchHistorial() {
    return _firestore
        .collection(_collection)
        .orderBy('creadaEn', descending: true)
        .limit(50)
        .snapshots()
        .map<Either<Failure, List<Quotation>>>((snap) {
      try {
        return Right(snap.docs.map(_fromDoc).toList());
      } catch (e) {
        return Left(Failure.database(message: e.toString()));
      }
    });
  }

  // ── Local cache helpers ───────────────────────────────────────────────────

  Future<void> _appendToLocalCache(Quotation q) async {
    final existing = await _cache.getJsonList(_cacheKey) ?? [];
    existing.insert(0, _quotationToMap(q));
    // Keep at most 50 locally.
    await _cache.setJsonList(_cacheKey, existing.take(50).toList());
  }

  Future<void> _removeFromLocalCache(String id) async {
    final existing = await _cache.getJsonList(_cacheKey);
    if (existing == null) return;
    await _cache.setJsonList(
        _cacheKey, existing.where((m) => m['id'] != id).toList());
  }

  Future<Either<Failure, List<Quotation>>> _historialFromCache(int limit) async {
    try {
      final raw = await _cache.getJsonList(_cacheKey);
      if (raw == null) return const Right([]);
      return Right(raw.take(limit).map(_quotationFromMap).toList());
    } catch (e) {
      return Left(Failure.cache(message: e.toString()));
    }
  }

  // ── Firestore serialization ───────────────────────────────────────────────

  Quotation _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      _quotationFromMap({...doc.data()!, 'id': doc.id});

  Quotation _quotationFromMap(Map<String, dynamic> map) => Quotation(
        id: map['id'] as String,
        vehiculoId: map['vehiculoId'] as String,
        vehiculoNombre: map['vehiculoNombre'] as String,
        origenDireccion: map['origenDireccion'] as String,
        destinoDireccion: map['destinoDireccion'] as String,
        resultadosPorRuta: (map['resultadosPorRuta'] as List)
            .cast<Map<String, dynamic>>()
            .map(_tariffResultFromMap)
            .toList(),
        precioGalonUsado: (map['precioGalonUsado'] as num).toDouble(),
        creadaEn: DateTime.parse(map['creadaEn'] as String),
        notasAdicionales: map['notasAdicionales'] as String?,
      );

  Map<String, dynamic> _quotationToMap(Quotation q) => {
        'id': q.id,
        'vehiculoId': q.vehiculoId,
        'vehiculoNombre': q.vehiculoNombre,
        'origenDireccion': q.origenDireccion,
        'destinoDireccion': q.destinoDireccion,
        'resultadosPorRuta':
            q.resultadosPorRuta.map(_tariffResultToMap).toList(),
        'precioGalonUsado': q.precioGalonUsado,
        'creadaEn': q.creadaEn.toIso8601String(),
        if (q.notasAdicionales != null) 'notasAdicionales': q.notasAdicionales,
      };

  TariffResult _tariffResultFromMap(Map<String, dynamic> map) => TariffResult(
        routeId: map['routeId'] as String,
        routeEtiqueta: map['routeEtiqueta'] as String,
        combustibleIdaGalones: (map['combustibleIdaGalones'] as num).toDouble(),
        combustibleVueltaGalones:
            (map['combustibleVueltaGalones'] as num).toDouble(),
        combustibleIdaSoles: (map['combustibleIdaSoles'] as num).toDouble(),
        combustibleVueltaSoles:
            (map['combustibleVueltaSoles'] as num).toDouble(),
        peajesTotalesSoles: (map['peajesTotalesSoles'] as num).toDouble(),
        peajesAjustadosManualmente:
            map['peajesAjustadosManualmente'] as bool? ?? false,
        totalSoles: (map['totalSoles'] as num).toDouble(),
        totalDolares: (map['totalDolares'] as num).toDouble(),
        tipoCambioUsado: (map['tipoCambioUsado'] as num).toDouble(),
        distanciaKm: (map['distanciaKm'] as num).toDouble(),
        duracionEstimada:
            Duration(milliseconds: map['duracionEstimadaMs'] as int),
        calculadoEn: DateTime.parse(map['calculadoEn'] as String),
      );

  Map<String, dynamic> _tariffResultToMap(TariffResult r) => {
        'routeId': r.routeId,
        'routeEtiqueta': r.routeEtiqueta,
        'combustibleIdaGalones': r.combustibleIdaGalones,
        'combustibleVueltaGalones': r.combustibleVueltaGalones,
        'combustibleIdaSoles': r.combustibleIdaSoles,
        'combustibleVueltaSoles': r.combustibleVueltaSoles,
        'peajesTotalesSoles': r.peajesTotalesSoles,
        'peajesAjustadosManualmente': r.peajesAjustadosManualmente,
        'totalSoles': r.totalSoles,
        'totalDolares': r.totalDolares,
        'tipoCambioUsado': r.tipoCambioUsado,
        'distanciaKm': r.distanciaKm,
        'duracionEstimadaMs': r.duracionEstimada.inMilliseconds,
        'calculadoEn': r.calculadoEn.toIso8601String(),
      };
}

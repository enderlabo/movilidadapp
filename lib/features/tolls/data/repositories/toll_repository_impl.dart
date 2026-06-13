import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/toll.dart';
import '../../domain/repositories/i_toll_repository.dart';

class TollRepositoryImpl implements ITollRepository {
  final FirebaseFirestore _firestore;

  static const _collection = 'tolls';

  const TollRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<Either<Failure, List<Toll>>> getAllTolls() async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('activo', isEqualTo: true)
          .get();
      return Right(snap.docs.map(_fromDoc).toList());
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Toll>>> findTollsNearby({
    required double lat,
    required double lng,
    double radiusKm = 0.5,
  }) async {
    // Firestore doesn't support geo queries natively.
    // We fetch all active tolls and filter in memory (catalog is small, <500 entries).
    final all = await getAllTolls();
    return all.map((tolls) => tolls.where((t) {
          final dlat = (t.lat - lat).abs();
          final dlng = (t.lng - lng).abs();
          // Rough bounding box: 1 degree ≈ 111 km
          final degRadius = radiusKm / 111.0;
          return dlat <= degRadius && dlng <= degRadius;
        }).toList());
  }

  @override
  Future<Either<Failure, Toll>> createToll(Toll toll) async {
    try {
      await _firestore.collection(_collection).doc(toll.id).set(_toMap(toll));
      return Right(toll);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Toll>> updateTollTarifa({
    required String tollId,
    required TipoVehiculo tipoVehiculo,
    required double nuevoMontoSoles,
    String? nota,
  }) async {
    try {
      final ref = _firestore.collection(_collection).doc(tollId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception('Toll not found: $tollId');

        final existing = _fromDoc(snap);
        final updatedTarifas = Map<TipoVehiculo, double>.from(existing.tarifasPorTipo)
          ..[tipoVehiculo] = nuevoMontoSoles;

        tx.update(ref, {
          'tarifasPorTipo': updatedTarifas.map((k, v) => MapEntry(k.name, v)),
          'fuente': TollFuente.confirmadoJefa.name,
          'actualizadoEn': DateTime.now().toIso8601String(),
          if (nota != null) 'notasAdicionales': nota,
        });
      });

      final updated = await _firestore.collection(_collection).doc(tollId).get();
      return Right(_fromDoc(updated));
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deactivateToll(String tollId) async {
    try {
      await _firestore.collection(_collection).doc(tollId).update({
        'activo': false,
        'actualizadoEn': DateTime.now().toIso8601String(),
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Toll>>> watchTolls() {
    return _firestore
        .collection(_collection)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map<Either<Failure, List<Toll>>>((snap) {
      try {
        return Right(snap.docs.map(_fromDoc).toList());
      } catch (e) {
        return Left(Failure.database(message: e.toString()));
      }
    });
  }

  // ── Firestore serialization ───────────────────────────────────────────────

  Toll _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    final tarifasRaw = map['tarifasPorTipo'] as Map<String, dynamic>? ?? {};
    return Toll(
      id: doc.id,
      nombre: map['nombre'] as String,
      ubicacion: map['ubicacion'] as String,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      tarifasPorTipo: tarifasRaw.map(
        (k, v) => MapEntry(TipoVehiculo.values.byName(k), (v as num).toDouble()),
      ),
      fuente: TollFuente.values.byName(map['fuente'] as String),
      activo: map['activo'] as bool? ?? true,
      creadoEn: DateTime.parse(map['creadoEn'] as String),
      actualizadoEn: DateTime.parse(map['actualizadoEn'] as String),
      notasAdicionales: map['notasAdicionales'] as String?,
    );
  }

  Map<String, dynamic> _toMap(Toll t) => {
        'nombre': t.nombre,
        'ubicacion': t.ubicacion,
        'lat': t.lat,
        'lng': t.lng,
        'tarifasPorTipo': t.tarifasPorTipo.map((k, v) => MapEntry(k.name, v)),
        'fuente': t.fuente.name,
        'activo': t.activo,
        'creadoEn': t.creadoEn.toIso8601String(),
        'actualizadoEn': t.actualizadoEn.toIso8601String(),
        if (t.notasAdicionales != null) 'notasAdicionales': t.notasAdicionales,
      };
}

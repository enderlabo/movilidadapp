import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/tarifa_zona.dart';
import '../../domain/repositories/i_tarifa_zona_repository.dart';

class TarifaZonaRepositoryImpl implements ITarifaZonaRepository {
  final FirebaseFirestore _firestore;
  static const _col = 'tarifas';

  const TarifaZonaRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<Either<Failure, List<TarifaZona>>> watchTarifas() {
    return _firestore
        .collection(_col)
        .where('active', isEqualTo: true)
        .snapshots()
        .map<Either<Failure, List<TarifaZona>>>((snap) {
      try {
        final list = snap.docs.map(_fromDoc).toList()
          ..sort((a, b) => a.distritoOrigen.compareTo(b.distritoOrigen));
        return Right(list);
      } catch (e) {
        return Left(Failure.database(message: e.toString()));
      }
    });
  }

  @override
  Future<Either<Failure, List<TarifaZona>>> getTarifas() async {
    try {
      final snap = await _firestore
          .collection(_col)
          .where('active', isEqualTo: true)
          .get();
      final list = snap.docs.map(_fromDoc).toList()
        ..sort((a, b) => a.distritoOrigen.compareTo(b.distritoOrigen));
      return Right(list);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TarifaZona?>> buscarTarifa({
    required String distritoOrigen,
    required String distritoDestino,
    required CategoriaVehiculo categoria,
  }) async {
    try {
      final snap = await _firestore
          .collection(_col)
          .where('originDistrict', isEqualTo: distritoOrigen)
          .where('destinationDistrict', isEqualTo: distritoDestino)
          .where('category', isEqualTo: _categoriaToString(categoria))
          .where('active', isEqualTo: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return const Right(null);
      return Right(_fromDoc(snap.docs.first));
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TarifaZona>> saveTarifa(TarifaZona tarifa) async {
    try {
      final id = tarifa.id.isEmpty ? const Uuid().v4() : tarifa.id;
      final data = _toMap(tarifa.copyWith(id: id));
      await _firestore.collection(_col).doc(id).set(data);
      return Right(tarifa.copyWith(id: id));
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTarifa(String id) async {
    try {
      await _firestore.collection(_col).doc(id).update({'active': false});
      return const Right(unit);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  TarifaZona _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return TarifaZona(
      id: doc.id,
      distritoOrigen: m['originDistrict'] as String? ?? m['distritoOrigen'] as String? ?? '',
      distritoDestino: m['destinationDistrict'] as String? ?? m['distritoDestino'] as String? ?? '',
      categoria: _categoriaFromString(m['category'] as String? ?? m['categoria'] as String?),
      precioSoles: (m['price'] as num? ?? m['precioSoles'] as num? ?? 0).toDouble(),
      precioMinSoles: (m['minPrice'] as num? ?? m['precioMinSoles'] as num?)?.toDouble(),
      precioMaxSoles: (m['maxPrice'] as num? ?? m['precioMaxSoles'] as num?)?.toDouble(),
      activo: m['active'] as bool? ?? m['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _toMap(TarifaZona t) => {
        'originDistrict': t.distritoOrigen,
        'destinationDistrict': t.distritoDestino,
        'category': _categoriaToString(t.categoria),
        'price': t.precioSoles,
        if (t.precioMinSoles != null) 'minPrice': t.precioMinSoles,
        if (t.precioMaxSoles != null) 'maxPrice': t.precioMaxSoles,
        'active': t.activo,
      };

  static CategoriaVehiculo _categoriaFromString(String? s) => switch (s) {
        'small' || 'pequeno' => CategoriaVehiculo.pequeno,
        'large' || 'grande' => CategoriaVehiculo.grande,
        _ => CategoriaVehiculo.pequeno,
      };

  static String _categoriaToString(CategoriaVehiculo c) => switch (c) {
        CategoriaVehiculo.pequeno => 'small',
        CategoriaVehiculo.grande => 'large',
      };
}

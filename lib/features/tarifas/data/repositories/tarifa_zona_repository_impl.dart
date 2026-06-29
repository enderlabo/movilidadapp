import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/repository_guard.dart';
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
    return guardStream(
      _firestore.collection(_col).where('active', isEqualTo: true).snapshots(),
      (snap) => snap.docs.map(_fromDoc).toList()
        ..sort((a, b) => a.distritoOrigen.compareTo(b.distritoOrigen)),
    );
  }

  @override
  Future<Either<Failure, List<TarifaZona>>> getTarifas() {
    return guardFuture(() async {
      final snap = await _firestore
          .collection(_col)
          .where('active', isEqualTo: true)
          .get();
      return snap.docs.map(_fromDoc).toList()
        ..sort((a, b) => a.distritoOrigen.compareTo(b.distritoOrigen));
    });
  }

  @override
  Future<Either<Failure, TarifaZona?>> buscarTarifa({
    required String distritoOrigen,
    required String distritoDestino,
    required CategoriaVehiculo categoria,
  }) {
    return guardFuture(() async {
      final snap = await _firestore
          .collection(_col)
          .where('originDistrict', isEqualTo: distritoOrigen)
          .where('destinationDistrict', isEqualTo: distritoDestino)
          .where('category', isEqualTo: categoria.firestoreEn)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();
      return snap.docs.isEmpty ? null : _fromDoc(snap.docs.first);
    });
  }

  @override
  Future<Either<Failure, TarifaZona>> saveTarifa(TarifaZona tarifa) {
    return guardFuture(() async {
      final id = tarifa.id.isEmpty ? const Uuid().v4() : tarifa.id;
      await _firestore.collection(_col).doc(id).set(_toMap(tarifa.copyWith(id: id)));
      return tarifa.copyWith(id: id);
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteTarifa(String id) {
    return guardFuture(() async {
      await _firestore.collection(_col).doc(id).update({'active': false});
      return unit;
    });
  }

  TarifaZona _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return TarifaZona(
      id: doc.id,
      distritoOrigen: m['originDistrict'] as String? ?? m['distritoOrigen'] as String? ?? '',
      distritoDestino: m['destinationDistrict'] as String? ?? m['distritoDestino'] as String? ?? '',
      categoria: CategoriaVehiculo.fromFirestoreEn(m['category'] as String? ?? m['categoria'] as String?),
      precioSoles: (m['price'] as num? ?? m['precioSoles'] as num? ?? 0).toDouble(),
      precioMinSoles: (m['minPrice'] as num? ?? m['precioMinSoles'] as num?)?.toDouble(),
      precioMaxSoles: (m['maxPrice'] as num? ?? m['precioMaxSoles'] as num?)?.toDouble(),
      activo: m['active'] as bool? ?? m['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _toMap(TarifaZona t) => {
        'originDistrict': t.distritoOrigen,
        'destinationDistrict': t.distritoDestino,
        'category': t.categoria.firestoreEn,
        'price': t.precioSoles,
        if (t.precioMinSoles != null) 'minPrice': t.precioMinSoles,
        if (t.precioMaxSoles != null) 'maxPrice': t.precioMaxSoles,
        'active': t.activo,
      };
}

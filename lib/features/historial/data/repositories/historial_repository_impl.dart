import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/repository_guard.dart';
import '../../../tarifas/domain/entities/cotizacion_tarifario.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/repositories/i_historial_repository.dart';

class HistorialRepositoryImpl implements IHistorialRepository {
  final FirebaseFirestore _firestore;
  static const _col = 'historial';

  const HistorialRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Stream<Either<Failure, List<CotizacionTarifario>>> watchHistorial() {
    return guardStream(
      _firestore
          .collection(_col)
          .orderBy('generadaEn', descending: true)
          .limit(50)
          .snapshots(),
      (snap) => snap.docs.map(_fromDoc).toList(),
    );
  }

  @override
  Future<Either<Failure, Unit>> guardar(CotizacionTarifario cotizacion) {
    return guardFuture(() async {
      await _firestore.collection(_col).doc(cotizacion.id).set(_toMap(cotizacion));
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> eliminar(String id) {
    return guardFuture(() async {
      await _firestore.collection(_col).doc(id).delete();
      return unit;
    });
  }

  CotizacionTarifario _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return CotizacionTarifario(
      id: doc.id,
      categoria: CategoriaVehiculo.fromKey(m['categoria'] as String?),
      vehiculoNombre: m['vehiculoNombre'] as String? ?? '',
      origenDireccion: m['origenDireccion'] as String? ?? '',
      destinoDireccion: m['destinoDireccion'] as String? ?? '',
      tarifaPorKm: (m['tarifaPorKm'] as num? ?? 0).toDouble(),
      distanciaKm: (m['distanciaKm'] as num? ?? 0).toDouble(),
      costoKilometraje: (m['costoKilometraje'] as num? ?? 0).toDouble(),
      costoTiempo: (m['costoTiempo'] as num? ?? 0).toDouble(),
      pesoKg: (m['pesoKg'] as num? ?? 0).toDouble(),
      costoPeso: (m['costoPeso'] as num? ?? 0).toDouble(),
      precioTotal: (m['precioTotal'] as num? ?? 0).toDouble(),
      duracionEstimada:
          Duration(minutes: (m['duracionMinutos'] as num? ?? 0).toInt()),
      generadaEn: (m['generadaEn'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> _toMap(CotizacionTarifario c) => {
        'vehiculoNombre': c.vehiculoNombre,
        'categoria': c.categoria.key,
        'origenDireccion': c.origenDireccion,
        'destinoDireccion': c.destinoDireccion,
        'tarifaPorKm': c.tarifaPorKm,
        'distanciaKm': c.distanciaKm,
        'costoKilometraje': c.costoKilometraje,
        'costoTiempo': c.costoTiempo,
        'pesoKg': c.pesoKg,
        'costoPeso': c.costoPeso,
        'precioTotal': c.precioTotal,
        'duracionMinutos': c.duracionEstimada.inMinutes,
        'generadaEn': Timestamp.fromDate(c.generadaEn),
      };
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/i_vehicle_repository.dart';

class VehicleRepositoryImpl implements IVehicleRepository {
  final FirebaseFirestore _firestore;

  static const _collection = 'vehicles';

  const VehicleRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<Either<Failure, List<Vehicle>>> getVehiculos() async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('activo', isEqualTo: true)
          .get();
      return Right(snap.docs.map((d) => _fromDoc(d)).toList());
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Vehicle>> getVehiculo(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        return const Left(Failure.database(message: 'Vehicle not found'));
      }
      return Right(_fromDoc(doc));
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Vehicle>> saveVehiculo(Vehicle vehicle) async {
    try {
      final data = _toMap(vehicle);
      await _firestore.collection(_collection).doc(vehicle.id).set(data);
      return Right(vehicle);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteVehiculo(String id) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update({'activo': false});
      return const Right(unit);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Vehicle>>> watchVehiculos() {
    return _firestore
        .collection(_collection)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map<Either<Failure, List<Vehicle>>>((snap) {
      try {
        return Right(snap.docs.map(_fromDoc).toList());
      } catch (e) {
        return Left(Failure.database(message: e.toString()));
      }
    });
  }

  // ── Firestore serialization ───────────────────────────────────────────────

  Vehicle _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data()!;
    return Vehicle(
      id: doc.id,
      nombre: map['nombre'] as String,
      placa: map['placa'] as String,
      tipo: TipoVehiculo.values.byName(map['tipo'] as String),
      capacidadTanqueGalones: (map['capacidadTanqueGalones'] as num).toDouble(),
      rendimientoKmPorGalonCargado:
          (map['rendimientoKmPorGalonCargado'] as num).toDouble(),
      rendimientoKmPorGalonVacio:
          (map['rendimientoKmPorGalonVacio'] as num).toDouble(),
      activo: map['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _toMap(Vehicle v) => {
        'nombre': v.nombre,
        'placa': v.placa,
        'tipo': v.tipo.name,
        'capacidadTanqueGalones': v.capacidadTanqueGalones,
        'rendimientoKmPorGalonCargado': v.rendimientoKmPorGalonCargado,
        'rendimientoKmPorGalonVacio': v.rendimientoKmPorGalonVacio,
        'activo': v.activo,
      };
}

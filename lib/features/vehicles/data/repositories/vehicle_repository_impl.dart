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
          .where('active', isEqualTo: true)
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
          .update({'active': false});
      return const Right(unit);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Vehicle>>> watchVehiculos() {
    return _firestore
        .collection(_collection)
        .where('active', isEqualTo: true)
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
  // Field names match what's stored in Firestore (English keys).

  Vehicle _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    return Vehicle(
      id: doc.id,
      nombre: m['name'] as String? ?? m['nombre'] as String? ?? '',
      placa: m['identifier'] as String? ?? m['placa'] as String? ?? '',
      tipo: _tipoFromString(m['type'] as String? ?? m['tipo'] as String? ?? 'truck'),
      capacidadTanqueGalones:
          (m['fuel capacity'] as num? ?? m['capacidadTanqueGalones'] as num? ?? 0).toDouble(),
      rendimientoKmPorGalonCargado:
          (m['fuel efficiency (km-gallon)'] as num? ?? m['rendimientoKmPorGalonCargado'] as num? ?? 28).toDouble(),
      rendimientoKmPorGalonVacio:
          (m['fuel efficiency empty'] as num? ?? m['rendimientoKmPorGalonVacio'] as num? ?? 38).toDouble(),
      activo: m['active'] as bool? ?? m['activo'] as bool? ?? true,
      categoria: _categoriaFromString(m['category'] as String? ?? m['categoria'] as String?),
    );
  }

  Map<String, dynamic> _toMap(Vehicle v) => {
        'name': v.nombre,
        'identifier': v.placa,
        'type': _tipoToString(v.tipo),
        'fuel capacity': v.capacidadTanqueGalones,
        'fuel efficiency (km-gallon)': v.rendimientoKmPorGalonCargado,
        'fuel efficiency empty': v.rendimientoKmPorGalonVacio,
        'active': v.activo,
        'category': _categoriaToString(v.categoria),
      };

  static TipoVehiculo _tipoFromString(String s) => switch (s) {
        'truck' || 'camion' => TipoVehiculo.camion,
        'van' || 'camioneta' => TipoVehiculo.camioneta,
        'pickup' || 'furgon' => TipoVehiculo.furgon,
        'semi' || 'tracto' => TipoVehiculo.tracto,
        _ => TipoVehiculo.otro,
      };

  static String _tipoToString(TipoVehiculo t) => switch (t) {
        TipoVehiculo.camion => 'truck',
        TipoVehiculo.camioneta => 'van',
        TipoVehiculo.furgon => 'pickup',
        TipoVehiculo.tracto => 'semi',
        TipoVehiculo.otro => 'other',
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/zona_tarifaria.dart';
import '../../domain/repositories/i_zona_tarifaria_repository.dart';

class ZonaTarifariaRepositoryImpl implements IZonaTarifariaRepository {
  final FirebaseFirestore _firestore;
  static const _col = 'zones';

  const ZonaTarifariaRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  static const _seedData = [
    {
      'zone': 'A',
      'name': 'Zona A',
      'districts': ['Santa Anita'],
      'minPrice': 70,
      'maxPrice': 80,
      'requiresQuote': false,
    },
    {
      'zone': 'B',
      'name': 'Zona B',
      'districts': ['Ate', 'El Agustino', 'San Luis'],
      'minPrice': 80,
      'maxPrice': 90,
      'requiresQuote': false,
    },
    {
      'zone': 'C',
      'name': 'Zona C',
      'districts': ['La Molina', 'Lurigancho-Chosica', 'San Borja'],
      'minPrice': 90,
      'maxPrice': 110,
      'requiresQuote': false,
    },
    {
      'zone': 'D',
      'name': 'Zona D',
      'districts': [
        'Surco',
        'Salamanca',
        'Miraflores',
        'Surquillo',
        'San Isidro',
        'Lince',
      ],
      'minPrice': 110,
      'maxPrice': 130,
      'requiresQuote': false,
    },
    {
      'zone': 'E',
      'name': 'Zona E',
      'districts': [
        'San Miguel',
        'Pueblo Libre',
        'Magdalena del Mar',
        'Jesús María',
        'Breña',
        'Lima',
      ],
      'minPrice': 120,
      'maxPrice': 140,
      'requiresQuote': false,
    },
    {
      'zone': 'F',
      'name': 'Zona F',
      'districts': [
        'Chorrillos',
        'Barranco',
        'La Perla',
        'Bellavista',
        'Callao',
        'Los Olivos',
        'San Martín de Porres',
      ],
      'minPrice': 130,
      'maxPrice': 160,
      'requiresQuote': false,
    },
    {
      'zone': 'G',
      'name': 'Zona G',
      'districts': [
        'Puente Piedra',
        'Carabayllo',
        'Villa El Salvador',
        'Villa María del Triunfo',
        'Ancón',
      ],
      'minPrice': 160,
      'maxPrice': 220,
      'requiresQuote': false,
    },
    {
      'zone': 'H',
      'name': 'Zona H',
      'districts': ['Chosica', 'Cieneguilla', 'Lurín', 'Pachacámac'],
      'minPrice': null,
      'maxPrice': null,
      'requiresQuote': true,
    },
  ];

  @override
  Stream<Either<Failure, List<ZonaTarifaria>>> watchZonas() {
    return _firestore
        .collection(_col)
        .where('active', isEqualTo: true)
        .snapshots()
        .map<Either<Failure, List<ZonaTarifaria>>>((snap) {
      try {
        final list = snap.docs.map(_fromDoc).toList()
          ..sort((a, b) => a.zona.compareTo(b.zona));
        return Right(list);
      } catch (e) {
        return Left(Failure.database(message: e.toString()));
      }
    });
  }

  @override
  Future<Either<Failure, List<ZonaTarifaria>>> getZonas() async {
    try {
      final snap = await _firestore
          .collection(_col)
          .where('active', isEqualTo: true)
          .get();
      final list = snap.docs.map(_fromDoc).toList()
        ..sort((a, b) => a.zona.compareTo(b.zona));
      return Right(list);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ZonaTarifaria>> saveZona(ZonaTarifaria zona) async {
    try {
      final id = zona.id.isEmpty ? const Uuid().v4() : zona.id;
      final data = _toMap(zona.copyWith(id: id));
      await _firestore.collection(_col).doc(id).set(data);
      return Right(zona.copyWith(id: id));
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteZona(String id) async {
    try {
      await _firestore.collection(_col).doc(id).update({'active': false});
      return const Right(unit);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> seedZonasDefault() async {
    try {
      // Check which zones already exist
      final existing = await _firestore.collection(_col).get();
      final existingZones = existing.docs
          .map((d) => d.data()['zone'] as String?)
          .whereType<String>()
          .toSet();

      final batch = _firestore.batch();
      for (final seed in _seedData) {
        final zone = seed['zone'] as String;
        if (existingZones.contains(zone)) continue;

        final id = const Uuid().v4();
        final ref = _firestore.collection(_col).doc(id);
        final districts = seed['districts'];
        final minPrice = seed['minPrice'];
        final maxPrice = seed['maxPrice'];
        batch.set(ref, {
          'zone': zone,
          'name': seed['name'],
          'districts': districts is List ? List<String>.from(districts) : <String>[],
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
          'requiresQuote': seed['requiresQuote'],
          'active': true,
        });
      }
      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return Left(Failure.database(message: e.toString()));
    }
  }

  ZonaTarifaria _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data()!;
    final rawDistricts = m['districts'];
    final distritos = rawDistricts is List
        ? List<String>.from(rawDistricts)
        : <String>[];
    return ZonaTarifaria(
      id: doc.id,
      zona: m['zone'] as String? ?? '',
      nombre: m['name'] as String? ?? '',
      distritos: distritos,
      precioMinSoles: (m['minPrice'] as num?)?.toDouble(),
      precioMaxSoles: (m['maxPrice'] as num?)?.toDouble(),
      requiereCotizar: m['requiresQuote'] as bool? ?? false,
      activo: m['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _toMap(ZonaTarifaria z) => {
        'zone': z.zona,
        'name': z.nombre,
        'districts': z.distritos,
        if (z.precioMinSoles != null) 'minPrice': z.precioMinSoles,
        if (z.precioMaxSoles != null) 'maxPrice': z.precioMaxSoles,
        'requiresQuote': z.requiereCotizar,
        'active': z.activo,
      };
}

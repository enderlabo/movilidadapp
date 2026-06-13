import 'package:flutter_test/flutter_test.dart';
import 'package:tarifario_movilidad/features/tolls/domain/services/toll_matcher_service.dart';
import 'package:tarifario_movilidad/features/tolls/domain/entities/toll.dart';

void main() {
  late TollMatcherService sut;

  // Peajes reales de la ruta Lima → Trujillo (Panamericana Norte)
  final peajeChao = Toll(
    id: 'chao-001',
    nombre: 'Peaje Chao',
    ubicacion: 'Km 395 Panamericana Norte, Chao, La Libertad',
    lat: -8.5387,
    lng: -78.9042,
    tarifasPorTipo: {
      TipoVehiculo.camion: 14.00,
      TipoVehiculo.camioneta: 7.00,
    },
    fuente: TollFuente.confirmadoJefa,
    creadoEn: DateTime(2025, 1, 1),
    actualizadoEn: DateTime(2025, 6, 1),
  );

  final peajeHuarmey = Toll(
    id: 'huarmey-001',
    nombre: 'Peaje Huarmey',
    ubicacion: 'Km 292 Panamericana Norte, Huarmey, Áncash',
    lat: -10.0688,
    lng: -78.1524,
    tarifasPorTipo: {
      TipoVehiculo.camion: 12.50,
    },
    fuente: TollFuente.detectadoMaps, // aún sin confirmar
    creadoEn: DateTime(2025, 3, 1),
    actualizadoEn: DateTime(2025, 3, 1),
  );

  // Peaje detectado por Maps — coordenadas con leve diferencia (GPS real)
  final chaoDetectado = TollDetectado(
    nombre: 'Peaje Chao',
    lat: -8.5390,   // 33m de diferencia respecto al catálogo — normal en GPS
    lng: -78.9045,
    montoEstimadoSoles: 10.00, // Maps subestima para Perú
  );

  // Peaje que Maps detectó pero NO está en el catálogo
  final pasamayoDetectado = TollDetectado(
    nombre: 'Variante de Pasamayo',
    lat: -11.6835,
    lng: -77.2109,
    montoEstimadoSoles: 0.0, // Maps no tiene datos de Perú
  );

  setUp(() => sut = const TollMatcherService());

  group('matchTolls — matching por proximidad', () {
    test('detecta peaje confirmado por proximidad aunque el monto de Maps sea distinto', () {
      final results = sut.matchTolls(
        detectados: [chaoDetectado],
        catalogo: [peajeChao, peajeHuarmey],
        tipoVehiculo: TipoVehiculo.camion,
      );

      expect(results.length, 1);
      expect(results.first.estaEnCatalogo, isTrue);
      expect(results.first.catalogMatch!.id, equals('chao-001'));
      // Usa el monto del catálogo (S/14), no el de Maps (S/10)
      expect(results.first.montoAUsar, equals(14.00));
      expect(results.first.requiereConfirmacion, isFalse);
    });

    test('peaje sin confirmar en catálogo → requiere revisión de la jefa', () {
      final huarmeyDetectado = TollDetectado(
        nombre: 'Peaje Huarmey',
        lat: -10.0690,
        lng: -78.1526,
        montoEstimadoSoles: 12.50,
      );

      final results = sut.matchTolls(
        detectados: [huarmeyDetectado],
        catalogo: [peajeChao, peajeHuarmey],
        tipoVehiculo: TipoVehiculo.camion,
      );

      expect(results.first.estaEnCatalogo, isTrue);
      expect(results.first.requiereConfirmacion, isTrue);
    });

    test('peaje nuevo (no en catálogo) → usa estimado de Maps, requiere confirmación', () {
      final results = sut.matchTolls(
        detectados: [pasamayoDetectado],
        catalogo: [peajeChao, peajeHuarmey],
        tipoVehiculo: TipoVehiculo.camion,
      );

      expect(results.first.estaEnCatalogo, isFalse);
      expect(results.first.montoAUsar, equals(0.0));
      expect(results.first.requiereConfirmacion, isTrue);
    });

    test('peaje sin tarifa para el tipo de vehículo → requiere confirmación', () {
      final results = sut.matchTolls(
        detectados: [chaoDetectado],
        catalogo: [peajeChao],
        tipoVehiculo: TipoVehiculo.tracto, // no tiene tarifa para tracto
      );

      expect(results.first.estaEnCatalogo, isTrue);
      expect(results.first.requiereConfirmacion, isTrue);
    });

    test('catálogo vacío → todos los peajes requieren confirmación', () {
      final results = sut.matchTolls(
        detectados: [chaoDetectado, pasamayoDetectado],
        catalogo: [],
        tipoVehiculo: TipoVehiculo.camion,
      );

      expect(results.length, 2);
      expect(results.every((r) => r.requiereConfirmacion), isTrue);
      expect(results.every((r) => !r.estaEnCatalogo), isTrue);
    });

    test('no hay falsos positivos — peajes alejados >0.5km no hacen match', () {
      // Lima Centro, muy lejos de Chao
      final detectedadoEnLima = TollDetectado(
        nombre: 'Peaje Lima',
        lat: -12.0464,
        lng: -77.0428,
        montoEstimadoSoles: 5.0,
      );

      final results = sut.matchTolls(
        detectados: [detectedadoEnLima],
        catalogo: [peajeChao],
        tipoVehiculo: TipoVehiculo.camion,
      );

      expect(results.first.estaEnCatalogo, isFalse);
    });
  });

  group('buildSnapshots', () {
    test('sin overrides — usa montos del matching', () {
      final matchResults = sut.matchTolls(
        detectados: [chaoDetectado],
        catalogo: [peajeChao],
        tipoVehiculo: TipoVehiculo.camion,
      );

      final snapshots = sut.buildSnapshots(matchResults: matchResults);

      expect(snapshots.first.montoUsado, equals(14.00));
      expect(snapshots.first.fueCorregidoPorJefa, isFalse);
    });

    test('con override de jefa — reemplaza el monto del catálogo', () {
      final matchResults = sut.matchTolls(
        detectados: [chaoDetectado],
        catalogo: [peajeChao],
        tipoVehiculo: TipoVehiculo.camion,
      );

      final snapshots = sut.buildSnapshots(
        matchResults: matchResults,
        overrides: {'chao-001': 16.50}, // SUTRAN subió el precio
      );

      expect(snapshots.first.montoUsado, equals(16.50));
      expect(snapshots.first.montoOriginalMaps, equals(10.00));
      expect(snapshots.first.fueCorregidoPorJefa, isTrue);
      expect(snapshots.first.tieneDiferencia, isTrue);
    });

    test('snapshot refleja diferencia entre Maps y catálogo', () {
      final matchResults = sut.matchTolls(
        detectados: [chaoDetectado],
        catalogo: [peajeChao],
        tipoVehiculo: TipoVehiculo.camion,
      );
      final snapshots = sut.buildSnapshots(matchResults: matchResults);

      // Maps estimó S/10, catálogo tiene S/14 → diferencia de S/4
      expect(snapshots.first.tieneDiferencia, isTrue);
      expect(snapshots.first.diferenciaSoles, closeTo(4.0, 0.01));
    });
  });

  group('totalPeajesSoles', () {
    test('suma correcta de múltiples peajes', () {
      final detectados = [
        chaoDetectado,
        TollDetectado(
          nombre: 'Peaje Huarmey',
          lat: -10.0688,
          lng: -78.1524,
          montoEstimadoSoles: 12.50,
        ),
      ];

      final matchResults = sut.matchTolls(
        detectados: detectados,
        catalogo: [peajeChao, peajeHuarmey],
        tipoVehiculo: TipoVehiculo.camion,
      );
      final snapshots = sut.buildSnapshots(matchResults: matchResults);
      final total = sut.totalPeajesSoles(snapshots);

      // Chao: S/14.00 (catálogo) + Huarmey: S/12.50 (catálogo)
      expect(total, closeTo(26.50, 0.01));
    });

    test('lista vacía retorna 0', () {
      expect(sut.totalPeajesSoles([]), equals(0.0));
    });
  });
}

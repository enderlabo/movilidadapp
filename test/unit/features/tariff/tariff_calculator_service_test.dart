import 'package:flutter_test/flutter_test.dart';
import 'package:tarifario_movilidad/features/tariff/domain/services/tariff_calculator_service.dart';
import 'package:tarifario_movilidad/features/vehicles/domain/entities/vehicle.dart';
import 'package:tarifario_movilidad/features/routes/domain/entities/route.dart';

void main() {
  late TariffCalculatorService sut;

  // Vehículo de prueba: camión de andamios
  const vehiculo = Vehicle(
    id: 'v1',
    nombre: 'Camión Volvo FH',
    placa: 'A1B-234',
    tipo: TipoVehiculo.camion,
    capacidadTanqueGalones: 100,
    rendimientoKmPorGalonCargado: 8.0,  // 8 km/galón con carga
    rendimientoKmPorGalonVacio: 12.0,   // 12 km/galón vacío
  );

  final ruta = RouteResult(
    id: 'r1',
    etiqueta: 'Ruta más rápida',
    distanciaKm: 100.0,
    duracionEstimada: const Duration(hours: 2),
    peajesEstimadosSoles: 25.0,
    tienePeajesConfiables: true,
    polilinea: [],
    resumenRuta: 'Panamericana Norte',
  );

  setUp(() {
    sut = const TariffCalculatorService();
  });

  group('calcularCombustibleSoles', () {
    test('ida con carga — usa rendimiento cargado', () {
      // 100 km / 8 km/galón = 12.5 galones × S/15.50 = S/193.75
      final resultado = sut.calcularCombustibleSoles(
        distanciaKm: 100,
        vehicle: vehiculo,
        conCarga: true,
        precioGalonSoles: 15.50,
      );

      expect(resultado, closeTo(193.75, 0.01));
    });

    test('vuelta vacía — usa rendimiento vacío (menor consumo)', () {
      // 100 km / 12 km/galón = 8.33 galones × S/15.50 = S/129.17
      final resultado = sut.calcularCombustibleSoles(
        distanciaKm: 100,
        vehicle: vehiculo,
        conCarga: false,
        precioGalonSoles: 15.50,
      );

      expect(resultado, closeTo(129.17, 0.01));
    });

    test('vuelta vacía siempre consume MENOS que ida cargada', () {
      final ida = sut.calcularCombustibleSoles(
        distanciaKm: 100,
        vehicle: vehiculo,
        conCarga: true,
        precioGalonSoles: 15.50,
      );
      final vuelta = sut.calcularCombustibleSoles(
        distanciaKm: 100,
        vehicle: vehiculo,
        conCarga: false,
        precioGalonSoles: 15.50,
      );

      expect(vuelta, lessThan(ida));
    });
  });

  group('calcularParaRuta', () {
    test('tarifa completa — suma correcta de todos los componentes', () {
      const precioGalon = 15.50;
      const tipoCambio = 3.75;

      final resultado = sut.calcularParaRuta(
        route: ruta,
        vehicle: vehiculo,
        precioGalonSoles: precioGalon,
        tipoCambio: tipoCambio,
      );

      // Ida: 100/8 × 15.50 = 193.75
      // Vuelta: 100/12 × 15.50 = 129.17
      // Peajes: 25.00
      // Total S/: 347.92
      // Total $: 347.92 / 3.75 = 92.78
      expect(resultado.combustibleIdaSoles, closeTo(193.75, 0.01));
      expect(resultado.combustibleVueltaSoles, closeTo(129.17, 0.01));
      expect(resultado.peajesTotalesSoles, equals(25.0));
      expect(resultado.totalSoles, closeTo(347.92, 0.01));
      expect(resultado.totalDolares, closeTo(92.78, 0.01));
      expect(resultado.peajesAjustadosManualmente, isFalse);
    });

    test('override de peajes — reemplaza el estimado de Maps', () {
      final resultado = sut.calcularParaRuta(
        route: ruta,
        vehicle: vehiculo,
        precioGalonSoles: 15.50,
        tipoCambio: 3.75,
        peajesOverrideSoles: 45.0, // jefa ajustó manualmente
      );

      expect(resultado.peajesTotalesSoles, equals(45.0));
      expect(resultado.peajesAjustadosManualmente, isTrue);
    });

    test('ruta más larga siempre cuesta más que ruta más corta', () {
      final rutaCorta = ruta;
      final rutaLarga = ruta.copyWith(
        id: 'r2',
        distanciaKm: 150.0,
        peajesEstimadosSoles: 30.0,
      );

      final tarifaCorta = sut.calcularParaRuta(
        route: rutaCorta,
        vehicle: vehiculo,
        precioGalonSoles: 15.50,
        tipoCambio: 3.75,
      );

      final tarifaLarga = sut.calcularParaRuta(
        route: rutaLarga,
        vehicle: vehiculo,
        precioGalonSoles: 15.50,
        tipoCambio: 3.75,
      );

      expect(tarifaLarga.totalSoles, greaterThan(tarifaCorta.totalSoles));
    });
  });

  group('calcularParaTodasLasRutas', () {
    test('retorna un resultado por cada ruta', () {
      final rutas = [
        ruta,
        ruta.copyWith(id: 'r2', etiqueta: 'Ruta alternativa', distanciaKm: 120),
      ];

      final resultados = sut.calcularParaTodasLasRutas(
        routes: rutas,
        vehicle: vehiculo,
        precioGalonSoles: 15.50,
        tipoCambio: 3.75,
      );

      expect(resultados.length, equals(2));
      expect(resultados.map((r) => r.routeId), containsAll(['r1', 'r2']));
    });
  });
}

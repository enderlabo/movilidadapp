import 'package:flutter_test/flutter_test.dart';
import 'package:tarifario_movilidad/features/tarifas/domain/entities/cotizacion_tarifario.dart';
import 'package:tarifario_movilidad/features/tarifas/domain/services/cotizacion_calculator_service.dart';
import 'package:tarifario_movilidad/features/tariff/domain/entities/tarifa_config.dart';
import 'package:tarifario_movilidad/features/vehicles/domain/entities/vehicle.dart';

void main() {
  const sut = CotizacionCalculatorService();

  const vehiculo = Vehicle(
    id: 'v1',
    nombre: 'Camión X',
    placa: 'ABC-123',
    tipo: TipoVehiculo.camion,
    capacidadTanqueGalones: 30,
    rendimientoKmPorGalonCargado: 28,
    rendimientoKmPorGalonVacio: 38,
    categoria: CategoriaVehiculo.grande,
  );

  const config = TarifaConfig(
    tarifasPorVehiculo: {'v1': 5.0},
    tarifaDefault: 10.0,
    factorTiempo: 0.20,
    tarifaPorKg: 0.10,
  );

  CotizacionTarifario calcular({
    double distanciaKm = 10,
    double pesoKg = 100,
    Vehicle veh = vehiculo,
  }) =>
      sut.calcular(
        id: 'fixed-id',
        vehiculo: veh,
        config: config,
        distanciaKm: distanciaKm,
        pesoKg: pesoKg,
        duracionEstimada: const Duration(minutes: 30),
        origenDireccion: 'Origen',
        destinoDireccion: 'Destino',
        generadaEn: DateTime(2026, 1, 1),
      );

  test('aplica el multiplicador ×2 a km, tiempo y peso', () {
    final c = calcular();

    // tarifaPorKm = 5 (from the map) · costoBaseKm = 5 × 10 = 50
    expect(c.tarifaPorKm, 5.0);
    expect(c.costoKilometraje, 100.0); // 50 × 2
    expect(c.costoTiempo, 20.0); // 50 × 0.20 × 2
    expect(c.costoPeso, 20.0); // 100 × 0.10 × 2
    expect(c.precioTotal, 140.0); // 100 + 20 + 20
  });

  test('usa la tarifa por defecto cuando el vehículo no tiene tarifa propia', () {
    const otro = Vehicle(
      id: 'desconocido',
      nombre: 'Otro',
      placa: 'XYZ-9',
      tipo: TipoVehiculo.furgon,
      capacidadTanqueGalones: 20,
      rendimientoKmPorGalonCargado: 25,
      rendimientoKmPorGalonVacio: 35,
    );
    final c = calcular(veh: otro);
    expect(c.tarifaPorKm, 10.0); // tarifaDefault
    expect(c.costoKilometraje, 200.0); // 10 × 10 × 2
  });

  test('los getters derivados son consistentes con el desglose', () {
    final c = calcular();
    expect(c.porcentajeTiempo, 20.0); // 20 / 100 × 100
    expect(c.tarifaPorKgUnitaria, 0.10); // 20 / 100 / 2
  });

  test('sin peso, el costo de peso es cero', () {
    final c = calcular(pesoKg: 0);
    expect(c.costoPeso, 0.0);
    expect(c.tarifaPorKgUnitaria, 0.0);
    expect(c.precioTotal, c.costoKilometraje + c.costoTiempo);
  });
}

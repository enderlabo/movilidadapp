import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle.freezed.dart';

/// Entidad de dominio: Vehículo de la empresa de andamios.
///
/// [rendimientoKmPorGalonCargado] — km/galón cuando sale del almacén con carga.
/// [rendimientoKmPorGalonVacio]   — km/galón en el viaje de retorno sin carga.
/// Por defecto el vehículo siempre sale cargado.
@freezed
class Vehicle with _$Vehicle {
  const factory Vehicle({
    required String id,
    required String nombre,
    required String placa,
    required TipoVehiculo tipo,
    required double capacidadTanqueGalones,
    required double rendimientoKmPorGalonCargado,
    required double rendimientoKmPorGalonVacio,
    @Default(true) bool activo,
    @Default(CategoriaVehiculo.pequeno) CategoriaVehiculo categoria,
  }) = _Vehicle;

  const Vehicle._();

  /// Rendimiento según si el vehículo lleva carga o no.
  double rendimientoPara({required bool conCarga}) =>
      conCarga ? rendimientoKmPorGalonCargado : rendimientoKmPorGalonVacio;

  /// Autonomía máxima en km según estado de carga.
  double autonomiaKm({required bool conCarga}) =>
      capacidadTanqueGalones * rendimientoPara(conCarga: conCarga);
}

enum TipoVehiculo {
  camion,
  camioneta,
  furgon,
  tracto,
  otro;

  String get displayName => switch (this) {
        TipoVehiculo.camion => 'Camión',
        TipoVehiculo.camioneta => 'Camioneta',
        TipoVehiculo.furgon => 'Furgón',
        TipoVehiculo.tracto => 'Tracto',
        TipoVehiculo.otro => 'Otro',
      };
}

enum CategoriaVehiculo {
  pequeno,
  grande;

  String get displayName => switch (this) {
        CategoriaVehiculo.pequeno => 'Camión Pequeño',
        CategoriaVehiculo.grande => 'Camión Grande',
      };

  String get shortName => switch (this) {
        CategoriaVehiculo.pequeno => 'PEQUEÑO',
        CategoriaVehiculo.grande => 'GRANDE',
      };
}

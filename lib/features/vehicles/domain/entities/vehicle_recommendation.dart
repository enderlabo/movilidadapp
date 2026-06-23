import 'package:flutter/foundation.dart';
import 'vehicle.dart';

/// Resultado de la matriz de selección de vehículo.
/// No es persistida — se recalcula en runtime cada vez que cambia destino o peso.
@immutable
class VehicleRecommendation {
  /// Placa del vehículo recomendado (identifica el documento en Firebase).
  final String placaRecomendada;
  final ZonaLima zona;
  final String razon;

  /// True cuando el vehículo necesita permiso especial (p.ej. Dongfeng en zona
  /// residencial con carga pesada).
  final bool requierePermisos;

  const VehicleRecommendation({
    required this.placaRecomendada,
    required this.zona,
    required this.razon,
    this.requierePermisos = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleRecommendation &&
          placaRecomendada == other.placaRecomendada &&
          zona == other.zona &&
          razon == other.razon &&
          requierePermisos == other.requierePermisos;

  @override
  int get hashCode =>
      Object.hash(placaRecomendada, zona, razon, requierePermisos);
}

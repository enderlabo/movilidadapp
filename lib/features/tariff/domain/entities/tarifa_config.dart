class TarifaConfig {
  final Map<String, double> tarifasPorVehiculo;
  final double tarifaDefault;
  final double factorTiempo;
  final double tarifaPorKg;

  const TarifaConfig({
    this.tarifasPorVehiculo = const {},
    this.tarifaDefault = 10.0,
    required this.factorTiempo,
    required this.tarifaPorKg,
  });

  static const defaults = TarifaConfig(
    tarifaDefault: 10.0,
    factorTiempo: 0.20,
    tarifaPorKg: 0.10,
  );

  double tarifaPara(String vehiculoId) =>
      tarifasPorVehiculo[vehiculoId] ?? tarifaDefault;

  TarifaConfig copyWith({
    Map<String, double>? tarifasPorVehiculo,
    double? tarifaDefault,
    double? factorTiempo,
    double? tarifaPorKg,
  }) =>
      TarifaConfig(
        tarifasPorVehiculo: tarifasPorVehiculo ?? this.tarifasPorVehiculo,
        tarifaDefault: tarifaDefault ?? this.tarifaDefault,
        factorTiempo: factorTiempo ?? this.factorTiempo,
        tarifaPorKg: tarifaPorKg ?? this.tarifaPorKg,
      );

  Map<String, dynamic> toJson() => {
        'tarifasPorVehiculo': tarifasPorVehiculo,
        'tarifaDefault': tarifaDefault,
        'factorTiempo': factorTiempo,
        'tarifaPorKg': tarifaPorKg,
      };

  factory TarifaConfig.fromJson(Map<String, dynamic> m) {
    final rawMap = m['tarifasPorVehiculo'] as Map<String, dynamic>?;
    final tarifasPorVehiculo = rawMap != null
        ? rawMap.map((k, v) => MapEntry(k, (v as num).toDouble()))
        : <String, double>{};

    // Backward compat: if old format used tarifaPequeno/Grande, use tarifaPequeno as default
    final tarifaDefault = (m['tarifaDefault'] as num? ??
            m['tarifaPequeno'] as num? ??
            10.0)
        .toDouble();

    return TarifaConfig(
      tarifasPorVehiculo: tarifasPorVehiculo,
      tarifaDefault: tarifaDefault,
      factorTiempo: (m['factorTiempo'] as num? ?? 0.20).toDouble(),
      tarifaPorKg: (m['tarifaPorKg'] as num? ?? 0.10).toDouble(),
    );
  }
}

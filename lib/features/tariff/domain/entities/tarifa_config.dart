class TarifaConfig {
  final double tarifaPequeno;
  final double tarifaGrande;
  final double factorTiempo;
  final double tarifaPorKg;

  const TarifaConfig({
    required this.tarifaPequeno,
    required this.tarifaGrande,
    required this.factorTiempo,
    required this.tarifaPorKg,
  });

  static const defaults = TarifaConfig(
    tarifaPequeno: 10.0,
    tarifaGrande: 12.0,
    factorTiempo: 0.20,
    tarifaPorKg: 0.10,
  );

  TarifaConfig copyWith({
    double? tarifaPequeno,
    double? tarifaGrande,
    double? factorTiempo,
    double? tarifaPorKg,
  }) =>
      TarifaConfig(
        tarifaPequeno: tarifaPequeno ?? this.tarifaPequeno,
        tarifaGrande: tarifaGrande ?? this.tarifaGrande,
        factorTiempo: factorTiempo ?? this.factorTiempo,
        tarifaPorKg: tarifaPorKg ?? this.tarifaPorKg,
      );

  Map<String, dynamic> toJson() => {
        'tarifaPequeno': tarifaPequeno,
        'tarifaGrande': tarifaGrande,
        'factorTiempo': factorTiempo,
        'tarifaPorKg': tarifaPorKg,
      };

  factory TarifaConfig.fromJson(Map<String, dynamic> m) => TarifaConfig(
        tarifaPequeno: (m['tarifaPequeno'] as num? ?? 10.0).toDouble(),
        tarifaGrande: (m['tarifaGrande'] as num? ?? 12.0).toDouble(),
        factorTiempo: (m['factorTiempo'] as num? ?? 0.20).toDouble(),
        tarifaPorKg: (m['tarifaPorKg'] as num? ?? 0.10).toDouble(),
      );
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'zona_tarifaria.freezed.dart';

@freezed
abstract class ZonaTarifaria with _$ZonaTarifaria {
  const factory ZonaTarifaria({
    required String id,
    required String zona,
    required String nombre,
    @Default([]) List<String> distritos,
    double? precioMinSoles,
    double? precioMaxSoles,
    @Default(false) bool requiereCotizar,
    @Default(true) bool activo,
  }) = _ZonaTarifaria;

  const ZonaTarifaria._();

  String get precioDisplay {
    if (requiereCotizar) return 'COTIZAR';
    if (precioMinSoles != null && precioMaxSoles != null) {
      return 'S/ ${precioMinSoles!.toStringAsFixed(0)} – S/ ${precioMaxSoles!.toStringAsFixed(0)}';
    }
    return '—';
  }

  bool get tieneRango => precioMinSoles != null && precioMaxSoles != null;
}

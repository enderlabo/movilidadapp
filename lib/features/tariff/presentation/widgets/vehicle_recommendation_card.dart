import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/services/vehicle_selection_service.dart';
import '../viewmodels/tariff_viewmodel.dart';

/// Muestra la zona detectada + razón de la recomendación de vehículo.
/// Aparece solo cuando hay un destino ingresado; se actualiza en tiempo real
/// cuando Maps refina la zona por el resumen de ruta (alta velocidad).
class VehicleRecommendationCard extends ConsumerWidget {
  const VehicleRecommendationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(
      tariffInputNotifierProvider.select((i) => i.recomendacion),
    );
    if (rec == null) return const SizedBox.shrink();

    final (color, icon, zonaNombre) = _zonaStyle(rec.zona);
    final esAltaVelocidadPorRuta = rec.zona == ZonaLima.altaVelocidad;
    final normPlaca =
        rec.placaRecomendada.toUpperCase().replaceAll(' ', '').replaceAll('-', '');
    final esGnv = normPlaca ==
        VehicleSelectionService.placaDongfeng
            .toUpperCase()
            .replaceAll(' ', '')
            .replaceAll('-', '');
    final fuelLabel = esGnv ? 'GNV' : 'GASOLINA';
    final fuelColor =
        esGnv ? const Color(0xFF4CAF50) : const Color(0xFFFF8C42);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Fila de zona ─────────────────────────────────────────
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    zonaNombre,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontFamily: 'Courier New',
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (esAltaVelocidadPorRuta) ...[
                  const SizedBox(width: 6),
                  _MiniChip(label: 'VÍA MAPS', color: color),
                ],
              ],
            ),

            const SizedBox(height: 6),

            // ── Razón de la recomendación ─────────────────────────────
            Text(
              rec.razon,
              style: TextStyle(
                color: context.c.textoPrimario,
                fontSize: 12,
                fontFamily: 'Courier New',
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 6),

            // ── Chips de combustible y permisos ───────────────────────
            Row(
              children: [
                _MiniChip(label: fuelLabel, color: fuelColor),
                if (rec.requierePermisos) ...[
                  const SizedBox(width: 6),
                  _MiniChip(label: '⚠ PERMISO', color: AppTheme.error),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static (Color, IconData, String) _zonaStyle(ZonaLima zona) =>
      switch (zona) {
        ZonaLima.residencialFinanciero => (
            const Color(0xFF5B9BD5),
            Icons.home_outlined,
            'RESIDENCIAL / FINANCIERO',
          ),
        ZonaLima.comercialIndustrial => (
            AppTheme.exito,
            Icons.store_outlined,
            'COMERCIAL / INDUSTRIAL',
          ),
        ZonaLima.periferica => (
            AppTheme.naranjaPrimario,
            Icons.location_city_outlined,
            'ZONA PERIFÉRICA',
          ),
        ZonaLima.altaVelocidad => (
            const Color(0xFF9C6FFF),
            Icons.speed_outlined,
            'RUTA ALTA VELOCIDAD',
          ),
      };
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontFamily: 'Courier New',
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

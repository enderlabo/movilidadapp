import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/tariff_result.dart';

/// Card que muestra el desglose de tarifa para UNA ruta.
/// Se genera una por cada ruta retornada por Maps (≥2).
class RouteResultCard extends StatelessWidget {
  final TariffResult result;
  final bool esMejorRuta;

  const RouteResultCard({
    super.key,
    required this.result,
    required this.esMejorRuta,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header ruta
          _RouteHeader(result: result, esMejorRuta: esMejorRuta),

          const SizedBox(height: AppTheme.spacingMd),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingMd),

          // Desglose
          _DesgloseFila(
            label: 'Combustible ida (cargado)',
            sublabel:
                '${result.combustibleIdaGalones.toStringAsFixed(2)} gal',
            valor: result.combustibleIdaSoles,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          _DesgloseFila(
            label: 'Combustible vuelta (vacío)',
            sublabel:
                '${result.combustibleVueltaGalones.toStringAsFixed(2)} gal',
            valor: result.combustibleVueltaSoles,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          _DesgloseFila(
            label: 'Peajes',
            sublabel:
                result.peajesAjustadosManualmente ? 'ajustado manualmente' : null,
            valor: result.peajesTotalesSoles,
            sublabelColor: result.peajesAjustadosManualmente
                ? Colors.orange
                : null,
          ),

          const SizedBox(height: AppTheme.spacingMd),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingMd),

          // Total
          _TotalFila(result: result),
        ],
      ),
    );
  }
}

class _RouteHeader extends StatelessWidget {
  final TariffResult result;
  final bool esMejorRuta;

  const _RouteHeader({required this.result, required this.esMejorRuta});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Ícono
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: esMejorRuta
                ? AppTheme.azulPrimario
                : AppTheme.azulClaro,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.route,
            size: 18,
            color: esMejorRuta ? AppTheme.blanco : AppTheme.azulPrimario,
          ),
        ),

        const SizedBox(width: AppTheme.spacingMd),

        // Nombre ruta + metadata
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    result.routeEtiqueta,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (esMejorRuta) ...[
                    const SizedBox(width: AppTheme.spacingXs),
                    _Badge(label: 'Más económica', color: AppTheme.azulPrimario),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${result.distanciaKm.toStringAsFixed(1)} km · '
                '${_formatDuracion(result.duracionEstimada)}',
                style: TextStyle(
                  color: AppTheme.textoSecundario,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuracion(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    }
    return '${d.inMinutes}min';
  }
}

class _DesgloseFila extends StatelessWidget {
  final String label;
  final String? sublabel;
  final double valor;
  final Color? sublabelColor;

  const _DesgloseFila({
    required this.label,
    required this.valor,
    this.sublabel,
    this.sublabelColor,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 13)),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: TextStyle(
                    fontSize: 11,
                    color: sublabelColor ?? AppTheme.grisMedium,
                  ),
                ),
            ],
          ),
        ),
        Text(
          fmt.format(valor),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TotalFila extends StatelessWidget {
  final TariffResult result;
  const _TotalFila({required this.result});

  @override
  Widget build(BuildContext context) {
    final fmtSoles = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final fmtDolares = NumberFormat.currency(locale: 'en_US', symbol: '\$ ');

    return Row(
      children: [
        const Text(
          'Total',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              fmtSoles.format(result.totalSoles),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.azulPrimario,
              ),
            ),
            Text(
              fmtDolares.format(result.totalDolares),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textoSecundario,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

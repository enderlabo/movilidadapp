import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tarifas/domain/entities/cotizacion_tarifario.dart';
import '../viewmodels/historial_viewmodel.dart';

class HistorialScreen extends ConsumerWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(historialStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de cotizaciones'),
      ),
      body: stream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history_outlined,
                      size: 48, color: AppTheme.grisMedium),
                  SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'Sin cotizaciones guardadas',
                    style: TextStyle(
                      color: AppTheme.textoSecundario,
                      fontFamily: 'Courier New',
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: lista.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTheme.spacingSm),
            itemBuilder: (_, i) => _HistorialCard(cotizacion: lista[i]),
          );
        },
      ),
    );
  }
}

class _HistorialCard extends ConsumerWidget {
  final CotizacionTarifario cotizacion;
  const _HistorialCard({required this.cotizacion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha =
        DateFormat('dd MMM yyyy · HH:mm', 'es').format(cotizacion.generadaEn);
    final minutos = cotizacion.duracionEstimada.inMinutes;
    final duracion =
        minutos >= 60 ? '${minutos ~/ 60}h ${minutos % 60}min' : '${minutos}min';
    final fmt = NumberFormat('#,##0.00', 'es');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fecha + categoría
          Row(
            children: [
              const Icon(Icons.access_time_outlined,
                  size: 13, color: AppTheme.textoMuted),
              const SizedBox(width: 4),
              Text(
                fecha,
                style: const TextStyle(
                  color: AppTheme.textoMuted,
                  fontFamily: 'Courier New',
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.azulPrimario),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSm),
                ),
                child: Text(
                  cotizacion.categoria.shortName,
                  style: const TextStyle(
                    color: AppTheme.azulPrimario,
                    fontFamily: 'Courier New',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // Vehículo
          Text(
            cotizacion.vehiculoNombre,
            style: const TextStyle(
              color: AppTheme.textoPrimario,
              fontFamily: 'Courier New',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          // Origen → Destino
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.radio_button_checked,
                  size: 12, color: AppTheme.azulPrimario),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  cotizacion.origenDireccion,
                  style: const TextStyle(
                    color: AppTheme.textoSecundario,
                    fontFamily: 'Courier New',
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text('│',
                style: TextStyle(color: AppTheme.grisMedium, fontSize: 10)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on,
                  size: 12, color: AppTheme.error),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  cotizacion.destinoDireccion,
                  style: const TextStyle(
                    color: AppTheme.textoSecundario,
                    fontFamily: 'Courier New',
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // Distancia + duración + precio
          Row(
            children: [
              const Icon(Icons.straighten_outlined,
                  size: 13, color: AppTheme.textoMuted),
              const SizedBox(width: 4),
              Text(
                '${cotizacion.distanciaKm.toStringAsFixed(1)} km × 2  ·  $duracion',
                style: const TextStyle(
                  color: AppTheme.textoMuted,
                  fontFamily: 'Courier New',
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                'S/ ${fmt.format(cotizacion.precioTotal)}',
                style: const TextStyle(
                  color: AppTheme.verdePrimario,
                  fontFamily: 'Courier New',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          // Botón eliminar
          const SizedBox(height: AppTheme.spacingSm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _confirmarEliminar(context, ref),
              icon: const Icon(Icons.delete_outline, size: 14),
              label: const Text('Eliminar'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cotización'),
        content: const Text('¿Seguro que deseas eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(historialRepositoryProvider)
          .eliminar(cotizacion.id);
    }
  }
}

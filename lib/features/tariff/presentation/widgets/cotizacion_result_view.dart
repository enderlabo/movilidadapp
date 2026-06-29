import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/route_share.dart';
import '../../../tarifas/domain/entities/cotizacion_tarifario.dart';
import '../../../routes/domain/entities/route.dart';
import '../viewmodels/tariff_viewmodel.dart';

/// View of a [CotizacionTarifario] breakdown (vehicle, route times, cost
/// breakdown and the GUARDAR/OLVIDAR actions).
///
/// Extracted from `tariff_screen.dart` to isolate the result presentation;
/// reused both in the desktop panel and the mobile bottom sheet.
class CotizacionResultView extends ConsumerWidget {
  final CotizacionTarifario cotizacion;
  const CotizacionResultView({super.key, required this.cotizacion});

  String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  String _duracion() => _formatDuracion(cotizacion.duracionEstimada);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(tariffViewModelProvider.notifier);
    final rutas = vm.rutasCargadas;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle
          Row(
            children: [
              const Icon(Icons.local_shipping,
                  size: 20, color: AppTheme.azulPrimario),
              const SizedBox(width: AppTheme.spacingXs),
              Expanded(
                child: Text(
                  cotizacion.vehiculoNombre,
                  style: TextStyle(
                    color: context.c.textoPrimario,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXs),

          // Distance + duration
          if (cotizacion.distanciaKm > 0)
            Row(
              children: [
                Icon(Icons.straighten_outlined,
                    size: 14, color: context.c.textoMuted),
                const SizedBox(width: 4),
                Text(
                  '${cotizacion.distanciaKm.toStringAsFixed(1)} km  ·  ${_duracion()}',
                  style: TextStyle(
                    color: context.c.textoMuted,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

          // Travel times: main route + alternatives
          if (rutas.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _RutasTiemposCard(rutas: rutas),
          ],

          const SizedBox(height: AppTheme.spacingLg),

          // Breakdown
          GlassCard(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Round-trip (×2) banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.naranjaPrimario.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusSm),
                    border: Border.all(
                        color: AppTheme.naranjaPrimario.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded,
                          size: 14, color: AppTheme.naranjaPrimario),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Precio incluye IDA Y VUELTA (× 2)',
                          style: TextStyle(
                            color: AppTheme.naranjaPrimario,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _DesgloseLine(
                  label:
                      'S/ ${_fmt(cotizacion.tarifaPorKm)} × ${cotizacion.distanciaKm.toStringAsFixed(1)} km × 2',
                  valor: cotizacion.costoKilometraje,
                  sublabel: 'entrega y recojo (ida + vuelta)',
                ),
                const Divider(height: AppTheme.spacingMd),
                _DesgloseLine(
                  label: '+ ${cotizacion.porcentajeTiempo.toStringAsFixed(0)}% tiempo × 2',
                  valor: cotizacion.costoTiempo,
                  sublabel: 'ida + vuelta',
                ),
                if (cotizacion.pesoKg > 0) ...[
                  const Divider(height: AppTheme.spacingMd),
                  _DesgloseLine(
                    label: '+ S/ ${_fmt(cotizacion.tarifaPorKgUnitaria)} × ${cotizacion.pesoKg.toStringAsFixed(0)} kg × 2',
                    valor: cotizacion.costoPeso,
                    sublabel: 'ida + vuelta',
                  ),
                ],
                const Divider(height: 1),
                const SizedBox(height: AppTheme.spacingMd),
                // Total
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'TOTAL',
                        style: TextStyle(
                          color: context.c.textoMuted,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      'S/ ${_fmt(cotizacion.precioTotal)}',
                      style: const TextStyle(
                        color: AppTheme.verdePrimario,
                        fontFamily: 'Courier New',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 13, color: AppTheme.naranjaPrimario),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Km · tiempo · peso  ×2  (ida + vuelta)',
                        style: TextStyle(
                          color: AppTheme.naranjaPrimario,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Actions with fade-in on appear
          _FadeInActions(
            onOlvidar: () => vm.olvidar(),
            onGuardar: () async {
              await vm.guardar();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Guardado en historial'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

/// GUARDAR / OLVIDAR buttons with fade-in on mount and fade-out on unmount
/// via the parent's AnimatedSwitcher.
class _FadeInActions extends StatefulWidget {
  final VoidCallback onOlvidar;
  final Future<void> Function() onGuardar;

  const _FadeInActions({required this.onOlvidar, required this.onGuardar});

  @override
  State<_FadeInActions> createState() => _FadeInActionsState();
}

class _FadeInActionsState extends State<_FadeInActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onOlvidar,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('OLVIDAR'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.c.textoSecundario,
                side: BorderSide(color: context.c.bordeInactivo),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _guardando
                  ? null
                  : () async {
                      setState(() => _guardando = true);
                      await widget.onGuardar();
                      if (mounted) setState(() => _guardando = false);
                    },
              icon: _guardando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(_guardando ? 'Guardando...' : 'GUARDAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.verdePrimario,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats a duration as "1h 20min" or "45min".
String _formatDuracion(Duration d) {
  final m = d.inMinutes;
  return m >= 60 ? '${m ~/ 60}h ${m % 60}min' : '${m}min';
}

/// Card listing the travel time of the main route and of each alternative
/// route returned by Maps, along with its distance.
class _RutasTiemposCard extends StatelessWidget {
  final List<RouteResult> rutas;
  const _RutasTiemposCard({required this.rutas});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  size: 16, color: AppTheme.azulPrimario),
              const SizedBox(width: 6),
              Text(
                'TIEMPO DE RECORRIDO',
                style: TextStyle(
                  color: context.c.textoSecundario,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          for (var i = 0; i < rutas.length; i++) ...[
            if (i > 0) const Divider(height: AppTheme.spacingMd),
            _RutaTiempoFila(ruta: rutas[i], esPrincipal: i == 0),
          ],
        ],
      ),
    );
  }
}

class _RutaTiempoFila extends StatelessWidget {
  final RouteResult ruta;
  final bool esPrincipal;
  const _RutaTiempoFila({required this.ruta, required this.esPrincipal});

  static const _shareService = RouteShareService();

  bool get _sePuedeCompartir => ruta.polilinea.length >= 2;

  Future<void> _compartir(BuildContext context) async {
    // The tapped widget's Rect anchors the share sheet popover on iPad/macOS;
    // it is ignored on other platforms.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await _shareService.compartir(ruta, origin: origin);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: esPrincipal ? AppTheme.azulPrimario : AppTheme.azulClaro,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.route,
            size: 16,
            color: esPrincipal ? AppTheme.blanco : AppTheme.azulPrimario,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    ruta.etiqueta,
                    style: TextStyle(
                      color: context.c.textoPrimario,
                      fontSize: 14,
                      fontWeight:
                          esPrincipal ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (esPrincipal)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.azulPrimario.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Más rápida',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.azulPrimario,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${ruta.distanciaKm.toStringAsFixed(1)} km',
                style: TextStyle(
                  color: context.c.textoMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 14, color: context.c.textoSecundario),
            const SizedBox(width: 4),
            Text(
              _formatDuracion(ruta.duracionEstimada),
              style: TextStyle(
                color: context.c.textoPrimario,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(width: AppTheme.spacingXs),
        IconButton(
          icon: const Icon(Icons.ios_share, size: 18),
          visualDensity: VisualDensity.compact,
          color: AppTheme.azulPrimario,
          tooltip: _sePuedeCompartir
              ? 'Compartir ruta en Google Maps'
              : 'Ruta sin trazado para compartir',
          onPressed: _sePuedeCompartir ? () => _compartir(context) : null,
        ),
      ],
    );
  }
}

class _DesgloseLine extends StatelessWidget {
  final String label;
  final double valor;
  final String sublabel;

  const _DesgloseLine({
    required this.label,
    required this.valor,
    required this.sublabel,
  });

  String _fmt(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.c.textoPrimario,
                  fontSize: 16,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  color: context.c.textoMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Text(
          'S/ ${_fmt(valor)}',
          style: TextStyle(
            color: context.c.textoSecundario,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../routes/domain/entities/route.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../tarifas/domain/entities/cotizacion_tarifario.dart';
import '../viewmodels/tariff_viewmodel.dart';

enum _MapStyle { mapa, satelite }

class MapWidget extends ConsumerStatefulWidget {
  const MapWidget({super.key});

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  final _mapController = MapController();
  _MapStyle _style = _MapStyle.mapa;

  static const _kBase = LatLng(-12.0473, -76.9721);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _locateBase() => _mapController.move(_kBase, 16);

  void _toggleStyle() => setState(
        () => _style =
            _style == _MapStyle.mapa ? _MapStyle.satelite : _MapStyle.mapa,
      );

  String get _tileUrl => _style == _MapStyle.mapa
      ? 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png'
      : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tariffViewModelProvider);
    final notifier = ref.read(tariffViewModelProvider.notifier);

    ref.listen(tariffViewModelProvider, (_, next) {
      next.whenOrNull(routesLoaded: _fitRoutes);
    });

    final input = ref.watch(tariffInputNotifierProvider);

    // Rutas desde el estado (cuando acaban de cargarse) o desde la caché del
    // notifier (cuando el estado ya pasó a success/loadingTariff).
    final routes = state.whenOrNull(routesLoaded: (r) => r) ??
        notifier.rutasCargadas;

    final rec = input.recomendacion;
    final routeColor = _colorParaZona(rec?.zona, rec?.placaRecomendada);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(-12.0482, -76.9736),
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              key: ValueKey(_style),
              urlTemplate: _tileUrl,
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.laborit.tarifario_movilidad',
            ),
            _buildPolylineLayer(routes, routeColor),
            _buildMarkerLayer(input),
          ],
        ),

        state.maybeWhen(
          routesLoaded: (routes) => Positioned(
            top: AppTheme.spacingMd,
            right: AppTheme.spacingMd,
            child: _RouteLegend(
              totalRutas: routes.length,
              routeColor: routeColor,
              esAltaVelocidad: rec?.zona == ZonaLima.altaVelocidad,
            ),
          ),
          success: (cotizacion) => Positioned(
            top: AppTheme.spacingMd,
            left: AppTheme.spacingMd,
            right: AppTheme.spacingMd,
            child: _MapInfoBar(cotizacion: cotizacion),
          ),
          orElse: () => const SizedBox.shrink(),
        ),

        Positioned(
          right: AppTheme.spacingMd,
          bottom: AppTheme.spacingXl,
          child: _MapControls(
            controller: _mapController,
            style: _style,
            onLocateBase: _locateBase,
            onToggleStyle: _toggleStyle,
          ),
        ),
      ],
    );
  }

  /// Mismo esquema de color que VehicleRecommendationCard._zonaStyle:
  /// altaVelocidad → morado, GNV → verde, Gasolina → naranja.
  static Color _colorParaZona(ZonaLima? zona, String? placa) {
    if (zona == ZonaLima.altaVelocidad) return const Color(0xFF9C6FFF);
    final esGnv = placa != null && placa.toUpperCase().contains('CCK');
    return esGnv ? AppTheme.exito : AppTheme.naranjaPrimario;
  }

  void _fitRoutes(List<RouteResult> routes) {
    if (routes.isEmpty) return;
    final points = routes
        .expand((r) => r.polilinea)
        .map((p) => LatLng(p.lat, p.lng))
        .toList();
    if (points.isEmpty) return;
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(64),
        ),
      );
    } catch (_) {}
  }

  Widget _buildMarkerLayer(TariffInput input) {
    final markers = <Marker>[
      if (input.origen != null)
        Marker(
          point: LatLng(input.origen!.lat, input.origen!.lng),
          child: const Icon(
            Icons.location_on,
            color: AppTheme.verdePrimario,
            size: 36,
            shadows: [Shadow(blurRadius: 6, color: AppTheme.verdeGlow)],
          ),
        ),
      if (input.destino != null)
        Marker(
          point: LatLng(input.destino!.lat, input.destino!.lng),
          child: const Icon(
            Icons.location_on,
            color: AppTheme.error,
            size: 36,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
        ),
    ];
    return MarkerLayer(markers: markers);
  }

  Widget _buildPolylineLayer(List<RouteResult> routes, Color routeColor) {
    final polylines = routes
        .where((r) => r.polilinea.isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((e) {
      final isPrimary = e.key == 0;
      return Polyline(
        points: e.value.polilinea.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: isPrimary
            ? routeColor
            : routeColor.withValues(alpha: 0.4),
        strokeWidth: isPrimary ? 5 : 2.5,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      );
    }).toList();

    // Siempre retorna PolylineLayer (incluso vacío) para evitar que flutter_map
    // descarte el layer cuando el tipo de widget cambia entre rebuilds.
    return PolylineLayer(polylines: polylines);
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

/// Leyenda que explica el significado de cada trazo de ruta en el mapa.
class _RouteLegend extends StatelessWidget {
  final int totalRutas;
  final Color routeColor;
  final bool esAltaVelocidad;

  const _RouteLegend({
    required this.totalRutas,
    required this.routeColor,
    required this.esAltaVelocidad,
  });

  @override
  Widget build(BuildContext context) {
    final alternativas = totalRutas - 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título — con badge morado si es alta velocidad
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$totalRutas RUTAS CALCULADAS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Courier New',
                  color: esAltaVelocidad ? routeColor : Colors.black54,
                  letterSpacing: 0.8,
                ),
              ),
              if (esAltaVelocidad) ...[
                const SizedBox(width: 5),
                Icon(Icons.speed_outlined, size: 11, color: routeColor),
              ],
            ],
          ),
          const SizedBox(height: 7),
          // Fila ruta principal
          _LegendRow(
            color: routeColor,
            strokeWidth: 5,
            label: esAltaVelocidad ? 'Vía rápida principal' : 'Ruta más rápida',
          ),
          if (alternativas > 0) ...[
            const SizedBox(height: 5),
            _LegendRow(
              color: routeColor.withValues(alpha: 0.45),
              strokeWidth: 2.5,
              label: alternativas == 1
                  ? '1 ruta alternativa'
                  : '$alternativas rutas alternativas',
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final String label;

  const _LegendRow({
    required this.color,
    required this.strokeWidth,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Muestra visual de la línea
        SizedBox(
          width: 28,
          height: 14,
          child: CustomPaint(
            painter: _LineSamplePainter(color: color, strokeWidth: strokeWidth),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Courier New',
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _LineSamplePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _LineSamplePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_LineSamplePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Barra horizontal de información que aparece sobre el mapa al calcular la
/// tarifa: monto total, tipo de camión, distancia, tiempo y peso. Los chips se
/// alinean a la derecha y envuelven a la siguiente línea si no caben.
/// Desaparece sola cuando el estado deja de ser `success` (al borrar o guardar).
class _MapInfoBar extends StatelessWidget {
  final CotizacionTarifario cotizacion;
  const _MapInfoBar({required this.cotizacion});

  String get _duracion {
    final m = cotizacion.duracionEstimada.inMinutes;
    return m >= 60 ? '${m ~/ 60}h ${m % 60}min' : '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: Icons.payments_outlined,
          label: cotizacion.precioDisplay,
          color: AppTheme.azulPrimario,
          filled: true,
        ),
        _InfoChip(
          icon: Icons.local_shipping_outlined,
          label: cotizacion.vehiculoNombre,
        ),
        if (cotizacion.distanciaKm > 0)
          _InfoChip(
            icon: Icons.straighten_outlined,
            label: '${cotizacion.distanciaKm.toStringAsFixed(1)} km',
          ),
        _InfoChip(
          icon: Icons.schedule_outlined,
          label: _duracion,
        ),
        if (cotizacion.pesoKg > 0)
          _InfoChip(
            icon: Icons.scale_outlined,
            label: '${cotizacion.pesoKg.toStringAsFixed(0)} kg',
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool filled;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.azulPrimario;
    final bg = filled
        ? accent.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.93);
    final fg = filled ? Colors.white : AppTheme.negro;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: filled ? Colors.white : accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  final MapController controller;
  final _MapStyle style;
  final VoidCallback onLocateBase;
  final VoidCallback onToggleStyle;

  const _MapControls({
    required this.controller,
    required this.style,
    required this.onLocateBase,
    required this.onToggleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isSat = style == _MapStyle.satelite;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ubicar base
        _ControlButton(
          tooltip: 'Ubicar base',
          onPressed: onLocateBase,
          child: const Icon(Icons.my_location, size: 20),
        ),

        const SizedBox(height: 8),

        // Toggle 2D / Satelite
        _ControlButton(
          tooltip: isSat ? 'Vista mapa' : 'Vista satelite',
          onPressed: onToggleStyle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSat ? Icons.map_outlined : Icons.satellite_alt_outlined,
                size: 18,
              ),
              const SizedBox(height: 2),
              Text(
                isSat ? '2D' : 'SAT',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Courier New',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Zoom + / -
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => controller.move(
                  controller.camera.center,
                  controller.camera.zoom + 1,
                ),
                tooltip: 'Acercar',
              ),
              const Divider(height: 1),
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: () => controller.move(
                  controller.camera.center,
                  controller.camera.zoom - 1,
                ),
                tooltip: 'Alejar',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final String tooltip;

  const _ControlButton({
    required this.child,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: SizedBox(
            width: 44,
            height: 48,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

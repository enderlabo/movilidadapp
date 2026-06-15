import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../routes/domain/entities/route.dart';
import '../viewmodels/tariff_viewmodel.dart';

enum _MapStyle { mapa, satelite }

/// Widget de mapa cross-platform usando flutter_map + OpenStreetMap / Esri.
class MapWidget extends ConsumerStatefulWidget {
  const MapWidget({super.key});

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  final _mapController = MapController();
  _MapStyle _style = _MapStyle.mapa;

  // Coordenadas de la base de operaciones (igual que _kOrigenFijo en viewmodel)
  static const _kBase = LatLng(-12.0473, -76.9721);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _locateBase() {
    _mapController.move(_kBase, 16);
  }

  void _toggleStyle() {
    setState(() {
      _style = _style == _MapStyle.mapa ? _MapStyle.satelite : _MapStyle.mapa;
    });
  }

  String get _tileUrl => _style == _MapStyle.mapa
      ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
      : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tariffViewModelProvider);
    final notifier = ref.read(tariffViewModelProvider.notifier);

    ref.listen(tariffViewModelProvider, (_, next) {
      next.whenOrNull(routesLoaded: _fitRoutes);
    });

    final input = ref.watch(tariffInputNotifierProvider);

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
              userAgentPackageName: 'com.laborit.tarifario_movilidad',
            ),
            _buildPolylineLayer(state, notifier.rutasCargadas),
            _buildMarkerLayer(input),
          ],
        ),

        state.maybeWhen(
          routesLoaded: (routes) => Positioned(
            top: AppTheme.spacingMd,
            right: AppTheme.spacingMd,
            child: _MapBadge(label: '${routes.length} rutas encontradas'),
          ),
          success: (cotizacion) => Positioned(
            top: AppTheme.spacingMd,
            right: AppTheme.spacingMd,
            child: _MapBadge(
              label: cotizacion.precioDisplay,
              color: AppTheme.azulPrimario,
            ),
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

  void _fitRoutes(List<RouteResult> routes) {
    if (routes.isEmpty) return;
    final points = routes
        .expand((r) => r.polilinea)
        .map((p) => LatLng(p.lat, p.lng))
        .toList();
    if (points.isEmpty) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(64),
      ),
    );
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

  Widget _buildPolylineLayer(
      TariffState state, List<RouteResult> rutasCargadas) {
    if (rutasCargadas.isEmpty) return const SizedBox.shrink();

    final polylines = rutasCargadas.asMap().entries.map((e) {
      final isPrimary = e.key == 0;
      return Polyline(
        points: e.value.polilinea.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: isPrimary
            ? AppTheme.verdePrimario
            : AppTheme.verdeSecundario.withValues(alpha: 0.5),
        strokeWidth: isPrimary ? 4 : 2,
      );
    }).toList();

    return PolylineLayer(polylines: polylines);
  }
}

// ─── Widgets auxiliares ────────────────────────────────────────────────────────

class _MapBadge extends StatelessWidget {
  final String label;
  final Color? color;
  const _MapBadge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.9) ??
            Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color != null ? Colors.white : AppTheme.textoPrimario,
        ),
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
        // ── Ubicar base ────────────────────────────────────────────────────
        _ControlButton(
          tooltip: 'Ubicar base',
          onPressed: onLocateBase,
          child: const Icon(Icons.my_location, size: 20),
        ),

        const SizedBox(height: AppTheme.spacingSm),

        // ── Toggle 2D / Satélite ───────────────────────────────────────────
        _ControlButton(
          tooltip: isSat ? 'Vista mapa' : 'Vista satélite',
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

        const SizedBox(height: AppTheme.spacingSm),

        // ── Zoom + / - ────────────────────────────────────────────────────
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../routes/domain/entities/route.dart';
import '../viewmodels/tariff_viewmodel.dart';

/// Widget de mapa cross-platform usando flutter_map + OpenStreetMap.
/// Funciona en Android, iOS, Windows, Web, macOS y Linux sin configuración extra.
class MapWidget extends ConsumerStatefulWidget {
  const MapWidget({super.key});

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

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
            initialCenter: LatLng(-12.0482, -76.9736), // Santa Anita — base de operaciones
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
          child: _ZoomControls(controller: _mapController),
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
    // Muestra la ruta mientras haya rutas cargadas, sin importar el estado de cálculo
    if (rutasCargadas.isEmpty) return const SizedBox.shrink();

    final polylines = rutasCargadas.asMap().entries.map((e) {
      final isPrimary = e.key == 0;
      return Polyline(
        points:
            e.value.polilinea.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: isPrimary
            ? AppTheme.verdePrimario
            : AppTheme.verdeSecundario.withValues(alpha: 0.5),
        strokeWidth: isPrimary ? 4 : 2,
      );
    }).toList();

    return PolylineLayer(polylines: polylines);
  }
}

// ─── Widgets auxiliares del mapa ──────────────────────────────────────────────

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
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
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

class _ZoomControls extends StatelessWidget {
  final MapController controller;
  const _ZoomControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
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
    );
  }
}

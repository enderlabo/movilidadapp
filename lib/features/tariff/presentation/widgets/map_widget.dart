import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/tariff_viewmodel.dart';

/// Widget de mapa adaptativo.
///
/// kIsWeb == true  → usa _WebMapWidget  (Google Maps JS API via HtmlElementView)
/// kIsWeb == false → usa _NativeMapWidget (google_maps_flutter SDK)
///
/// El dominio no sabe cuál se usa — es un detalle de presentación.
class MapWidget extends ConsumerWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return kIsWeb ? const _WebMapWidget() : const _NativeMapWidget();
  }
}

// ─── Mapa nativo (mobile + desktop) ──────────────────────────────────────────

class _NativeMapWidget extends ConsumerStatefulWidget {
  const _NativeMapWidget();

  @override
  ConsumerState<_NativeMapWidget> createState() => _NativeMapWidgetState();
}

class _NativeMapWidgetState extends ConsumerState<_NativeMapWidget> {
  // GoogleMapController? _controller;  // se inicializa al onMapCreated

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tariffViewModelProvider);

    // TODO: reemplazar con GoogleMap() real cuando se agreguen las dependencias
    // GoogleMap(
    //   initialCameraPosition: const CameraPosition(
    //     target: LatLng(-12.0464, -77.0428), // Lima centro
    //     zoom: 12,
    //   ),
    //   onMapCreated: (controller) => _controller = controller,
    //   polylines: _buildPolylines(state),
    //   markers: _buildMarkers(state),
    //   myLocationEnabled: false,
    //   zoomControlsEnabled: false,
    //   mapToolbarEnabled: false,
    // )

    return Stack(
      children: [
        // Placeholder del mapa (reemplazar con GoogleMap real)
        Container(
          color: const Color(0xFFE8F0F7),
          child: CustomPaint(
            painter: _MapPlaceholderPainter(),
            child: const SizedBox.expand(),
          ),
        ),

        // Indicador de rutas cargadas
        state.maybeWhen(
          routesLoaded: (routes) => Positioned(
            top: AppTheme.spacingMd,
            right: AppTheme.spacingMd,
            child: _MapBadge(
              label: '${routes.length} rutas encontradas',
            ),
          ),
          success: (quotation) => Positioned(
            top: AppTheme.spacingMd,
            right: AppTheme.spacingMd,
            child: _MapBadge(
              label: '${quotation.resultadosPorRuta.length} rutas calculadas',
              color: AppTheme.azulPrimario,
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),

        // Controles de zoom (custom para coincidir con el diseño glass)
        Positioned(
          right: AppTheme.spacingMd,
          bottom: AppTheme.spacingXl,
          child: _ZoomControls(),
        ),
      ],
    );
  }
}

// ─── Mapa web (JS Interop) ────────────────────────────────────────────────────

class _WebMapWidget extends ConsumerStatefulWidget {
  const _WebMapWidget();

  @override
  ConsumerState<_WebMapWidget> createState() => _WebMapWidgetState();
}

class _WebMapWidgetState extends ConsumerState<_WebMapWidget> {
  // In Flutter Web the map is mounted via HtmlElementView.
  // ignore: unused_field — used in the HtmlElementView TODO below.
  static const _viewType = 'google-maps-view';

  @override
  Widget build(BuildContext context) {
    // TODO: implementar cuando se configure el proyecto Flutter Web
    // En web real:
    // 1. Registrar el factory en main.dart:
    //    ui_web.platformViewRegistry.registerViewFactory(
    //      _viewType, (id) => _buildMapElement(id),
    //    );
    // 2. Usar HtmlElementView aquí:
    //    return HtmlElementView(viewType: _viewType);

    return Container(
      color: const Color(0xFFE8F0F7),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Color(0xFF90A4AE)),
            SizedBox(height: 12),
            Text(
              'Mapa web — requiere configuración\nde Google Maps JS API',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF78909C), fontSize: 13),
            ),
          ],
        ),
      ),
    );
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
        color: color?.withValues(alpha: 0.9) ?? Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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

class _ZoomControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () {/* _controller?.animateCamera(CameraUpdate.zoomIn()) */},
            tooltip: 'Acercar',
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: () {/* _controller?.animateCamera(CameraUpdate.zoomOut()) */},
            tooltip: 'Alejar',
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Grid minimalista que simula el mapa mientras no está integrado
    final paint = Paint()
      ..color = const Color(0xFFCFDAE7)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

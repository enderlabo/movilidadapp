import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tariff_result.dart';
import '../viewmodels/tariff_viewmodel.dart';
import '../widgets/address_search_field.dart';
import '../widgets/vehicle_selector.dart';
import '../widgets/map_widget.dart';
import '../widgets/route_result_card.dart';
import '../widgets/toll_review_sheet.dart';
import '../../../tolls/presentation/viewmodels/toll_viewmodel.dart';

/// Pantalla principal — punto de entrada de toda la app.
///
/// Layout A (mobile)   : mapa full screen + inputs flotantes + bottom sheet resultado.
/// Layout B (web/desk) : panel izquierdo inputs + mapa derecho + resultado inline.
class TariffScreen extends ConsumerWidget {
  const TariffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlatformUtils.isMobile(context)
        ? const _MobileLayout()
        : const _DesktopWebLayout();
  }
}

// ─── Layout A: Mobile ─────────────────────────────────────────────────────────

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tariffViewModelProvider);

    final isLoading = state.maybeWhen(
      loadingRoutes: () => true,
      loadingTariff: () => true,
      orElse: () => false,
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: MapWidget()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _FloatingInputPanel(),
          ),
          // Bottom sheet — only shown in success state.
          ...state.maybeWhen(
            success: (quotation) => [
              DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.15,
                maxChildSize: 0.85,
                builder: (_, controller) => _ResultBottomSheet(
                  quotation: quotation,
                  scrollController: controller,
                ),
              ),
            ],
            orElse: () => const <Widget>[],
          ),
          if (isLoading) const Positioned.fill(child: _LoadingOverlay()),
        ],
      ),
    );
  }
}

class _FloatingInputPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(tariffViewModelProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: GlassCard(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AddressSearchField(
                hint: 'Punto de salida',
                icon: Icons.radio_button_checked,
                iconColor: AppTheme.azulPrimario,
                onWaypointSelected: vm.setOrigen,
              ),
              const _RouteConnector(),
              AddressSearchField(
                hint: 'Punto de destino',
                icon: Icons.location_on,
                iconColor: const Color(0xFFD32F2F),
                onWaypointSelected: vm.setDestino,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              VehicleSelector(onSelected: vm.setVehiculo),
              const SizedBox(height: AppTheme.spacingMd),
              _CalculateButton(isMobile: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Layout B: Web / Desktop ──────────────────────────────────────────────────

class _DesktopWebLayout extends ConsumerWidget {
  const _DesktopWebLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping_outlined,
                color: AppTheme.azulPrimario, size: 20),
            const SizedBox(width: AppTheme.spacingSm),
            const Text('Tarifario de movilidad'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Historial',
            onPressed: () {/* go_router push historial */},
          ),
          IconButton(
            icon: const Icon(Icons.toll_outlined),
            tooltip: 'Catálogo de peajes',
            onPressed: () {/* go_router push peajes */},
          ),
          const SizedBox(width: AppTheme.spacingSm),
        ],
      ),
      body: Row(
        children: [
          // Panel izquierdo — inputs + resultado
          SizedBox(
            width: 380,
            child: _LeftPanel(),
          ),

          // Divisor
          VerticalDivider(
            width: 1,
            color: AppTheme.glassBorder,
          ),

          // Panel derecho — mapa
          const Expanded(child: MapWidget()),
        ],
      ),
    );
  }
}

class _LeftPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tariffViewModelProvider);
    final vm = ref.read(tariffViewModelProvider.notifier);

    return Container(
      color: AppTheme.grisClaro,
      child: Column(
        children: [
          // Formulario de búsqueda
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Origen
                _SectionLabel(label: 'Ruta'),
                const SizedBox(height: AppTheme.spacingSm),
                AddressSearchField(
                  hint: 'Punto de salida',
                  icon: Icons.radio_button_checked,
                  iconColor: AppTheme.azulPrimario,
                  onWaypointSelected: vm.setOrigen,
                ),
                const _RouteConnector(),
                AddressSearchField(
                  hint: 'Punto de destino',
                  icon: Icons.location_on,
                  iconColor: const Color(0xFFD32F2F),
                  onWaypointSelected: vm.setDestino,
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Vehículo
                _SectionLabel(label: 'Vehículo'),
                const SizedBox(height: AppTheme.spacingSm),
                VehicleSelector(onSelected: vm.setVehiculo),

                const SizedBox(height: AppTheme.spacingLg),
                _CalculateButton(isMobile: false),
              ],
            ),
          ),

          const Divider(height: 1),

          // Resultado
          Expanded(
            child: state.when(
              initial: () => const _EmptyState(),
              loadingRoutes: () =>
                  const _LoadingState(mensaje: 'Buscando rutas...'),
              loadingTariff: () =>
                  const _LoadingState(mensaje: 'Calculando tarifa...'),
              routesLoaded: (routes) => const _LoadingState(
                  mensaje: 'Selecciona vehículo y calcula'),
              success: (quotation) => ListView.separated(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                itemCount: quotation.resultadosPorRuta.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTheme.spacingSm),
                itemBuilder: (_, i) => RouteResultCard(
                  result: quotation.resultadosPorRuta[i],
                  esMejorRuta: quotation.rutaMasEconomica.routeId ==
                      quotation.resultadosPorRuta[i].routeId,
                ),
              ),
              error: (failure) => _ErrorState(mensaje: failure.userMessage),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets compartidos ──────────────────────────────────────────────────────

class _CalculateButton extends ConsumerWidget {
  final bool isMobile;
  const _CalculateButton({required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tariffViewModelProvider);
    final vm = ref.read(tariffViewModelProvider.notifier);
    final input = vm.input;

    final bool puedeCalcular = input.puedeCalcularTarifa &&
        !state.maybeWhen(
          loadingRoutes: () => true,
          loadingTariff: () => true,
          orElse: () => false,
        );

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: puedeCalcular
            ? () async {
                // 1. Search routes
                await vm.buscarRutas();
                // 2. Show toll review sheet if any tolls need confirmation
                final tollState = ref.read(tollMatchingViewModelProvider);
                final needsReview = tollState.whenOrNull(
                  done: (result) => result.requiereRevision,
                );
                if (needsReview == true && context.mounted) {
                  await _mostrarRevisionPeajes(context, ref);
                }
                // 3. Calculate tariff
                await vm.calcularTarifa();
              }
            : null,
        icon: const Icon(Icons.calculate_outlined, size: 18),
        label: const Text('Calcular tarifa'),
      ),
    );
  }

  Future<void> _mostrarRevisionPeajes(
      BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TollReviewSheet(),
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 19),
      child: Row(
        children: [
          SizedBox(
            height: 20,
            child: VerticalDivider(
              width: 2,
              color: AppTheme.grisMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textoSecundario,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route_outlined,
              size: 48, color: AppTheme.grisMedium),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Ingresa origen y destino\npara calcular la tarifa',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textoSecundario, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final String mensaje;
  const _LoadingState({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppTheme.spacingMd),
          Text(mensaje,
              style: TextStyle(color: AppTheme.textoSecundario)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String mensaje;
  const _ErrorState({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: AppTheme.error),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.error),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ResultBottomSheet extends StatelessWidget {
  final Quotation quotation;
  final ScrollController scrollController;
  const _ResultBottomSheet(
      {required this.quotation, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        itemCount: quotation.resultadosPorRuta.length + 1,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppTheme.spacingSm),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grisMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final result = quotation.resultadosPorRuta[i - 1];
          return RouteResultCard(
            result: result,
            esMejorRuta:
                quotation.rutaMasEconomica.routeId == result.routeId,
          );
        },
      ),
    );
  }
}

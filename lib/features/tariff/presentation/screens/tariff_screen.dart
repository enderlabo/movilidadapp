import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/error/failures.dart';
import '../../../tarifas/domain/entities/cotizacion_tarifario.dart';
import '../viewmodels/tariff_viewmodel.dart';
import '../widgets/address_search_field.dart';
import '../widgets/vehicle_selector.dart';
import '../widgets/map_widget.dart';
import '../widgets/toll_review_sheet.dart';
import '../../../tolls/presentation/viewmodels/toll_viewmodel.dart';
import '../../../../router/app_router.dart';
import 'settings_tarifas_sheet.dart';
import '../../../../../core/theme/theme_notifier.dart';

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
            success: (cotizacion) => [
              DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.15,
                maxChildSize: 0.85,
                builder: (_, controller) => _ResultBottomSheet(
                  cotizacion: cotizacion,
                  scrollController: controller,
                ),
              ),
            ],
            orElse: () => const <Widget>[],
          ),
          if (isLoading) const Positioned.fill(child: _LoadingOverlay()),
          // Botón toggle de tema (móvil)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Consumer(
                builder: (context, ref, _) {
                  final isLight = ref.watch(
                      themeModeProvider.select((m) => m == ThemeMode.light));
                  return IconButton(
                    icon: Icon(
                      isLight
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      size: 20,
                    ),
                    color: AppTheme.naranjaPrimario,
                    tooltip: isLight ? 'Modo oscuro' : 'Modo claro',
                    onPressed: () =>
                        ref.read(themeModeProvider.notifier).toggle(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingInputPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputVm = ref.read(tariffInputNotifierProvider.notifier);
    final resetCount = ref.watch(
        tariffInputNotifierProvider.select((i) => i.resetCount));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: GlassCard(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _OriginFijaWidget(),
              const _RouteConnector(),
              AddressSearchField(
                key: ValueKey('destino_$resetCount'),
                hint: 'Punto de destino',
                icon: Icons.location_on,
                iconColor: AppTheme.error,
                onWaypointSelected: inputVm.setDestino,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              VehicleSelector(
                key: ValueKey('vehiculo_$resetCount'),
                onSelected: inputVm.setVehiculo,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _PesoInputField(key: ValueKey('peso_$resetCount')),
              const SizedBox(height: AppTheme.spacingMd),
              const _CalculateRow(isMobile: true),
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
          children: const [
            Icon(Icons.local_shipping_outlined,
                color: AppTheme.azulPrimario, size: 20),
            SizedBox(width: AppTheme.spacingSm),
            Text('Tarifario de movilidad'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Historial',
            onPressed: () => context.push(AppRoutes.historial),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Información de tarifas',
            onPressed: () => context.push(AppRoutes.peajes),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurar tarifas',
            onPressed: () => mostrarSettingsTarifas(context),
          ),
          Consumer(
            builder: (context, ref, _) {
              final isLight = ref.watch(
                  themeModeProvider.select((m) => m == ThemeMode.light));
              return IconButton(
                icon: Icon(isLight
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined),
                tooltip: isLight ? 'Modo oscuro' : 'Modo claro',
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggle(),
              );
            },
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
          const VerticalDivider(
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
    final inputVm = ref.read(tariffInputNotifierProvider.notifier);
    final resetCount = ref.watch(tariffInputNotifierProvider.select((i) => i.resetCount));

    return Container(
      color: context.c.superficieBase,
      child: Column(
        children: [
          // Formulario de búsqueda
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Origen
                const _SectionLabel(label: 'Ruta'),
                const SizedBox(height: AppTheme.spacingSm),
                const _OriginFijaWidget(),
                const _RouteConnector(),
                AddressSearchField(
                  key: ValueKey('destino_$resetCount'),
                  hint: 'Punto de destino',
                  icon: Icons.location_on,
                  iconColor: AppTheme.error,
                  onWaypointSelected: inputVm.setDestino,
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // Vehículo
                const _SectionLabel(label: 'Vehículo'),
                const SizedBox(height: AppTheme.spacingSm),
                VehicleSelector(
                  key: ValueKey('vehiculo_$resetCount'),
                  onSelected: inputVm.setVehiculo,
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // Peso
                const _SectionLabel(label: 'Carga'),
                const SizedBox(height: AppTheme.spacingSm),
                _PesoInputField(key: ValueKey('peso_$resetCount')),

                const SizedBox(height: AppTheme.spacingLg),
                const _CalculateRow(isMobile: false),
              ],
            ),
          ),

          const Divider(height: 1),

          // Resultado con fade entre estados
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: KeyedSubtree(
                key: ValueKey(state.runtimeType),
                child: state.when(
              initial: () => const _EmptyState(),
              loadingRoutes: () => const _EmptyState(),
              loadingTariff: () =>
                  const _LoadingState(mensaje: 'Calculando tarifa...'),
              routesLoaded: (_) => const _RouteReadyState(),
              success: (cotizacion) => _CotizacionResult(cotizacion: cotizacion),
              sinTarifa: (origen, destino) => _SinTarifaState(
                distritoOrigen: origen,
                distritoDestino: destino,
              ),
              error: (failure) => _ErrorState(mensaje: failure.userMessage),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets compartidos ──────────────────────────────────────────────────────

/// Fila con botón Calcular + botón Reset.
class _CalculateRow extends ConsumerWidget {
  final bool isMobile;
  const _CalculateRow({required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tariffViewModelProvider);
    final input = ref.watch(tariffInputNotifierProvider);
    final vm = ref.read(tariffViewModelProvider.notifier);

    final bool isLoading = state.maybeWhen(
      loadingRoutes: () => true,
      loadingTariff: () => true,
      orElse: () => false,
    );
    final bool puedeCalcular = input.puedeCalcularTarifa && !isLoading;
    final bool hayContenido = input.destino != null || state.maybeWhen(
      success: (_) => true,
      routesLoaded: (_) => true,
      orElse: () => false,
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: puedeCalcular
                  ? () async {
                      if (vm.rutasCargadas.isEmpty) await vm.buscarRutas();
                      if (!context.mounted) return;
                      final tollState = ref.read(tollMatchingViewModelProvider);
                      final needsReview = tollState.whenOrNull(
                        done: (result) => result.requiereRevision,
                      );
                      if (needsReview == true && context.mounted) {
                        await _mostrarRevisionPeajes(context, ref);
                      }
                      if (context.mounted) await vm.calcularTarifa();
                    }
                  : null,
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Calcular tarifa'),
            ),
          ),
        ),
        if (hayContenido) ...[
          const SizedBox(width: AppTheme.spacingSm),
          SizedBox(
            height: 48,
            width: 48,
            child: IconButton.outlined(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              tooltip: 'Nueva búsqueda',
              onPressed: () => vm.resetear(),
              style: IconButton.styleFrom(
                foregroundColor: context.c.textoSecundario,
                side: BorderSide(color: context.c.bordeInactivo),
              ),
            ),
          ),
        ],
      ],
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

class _CotizacionResult extends ConsumerWidget {
  final CotizacionTarifario cotizacion;
  const _CotizacionResult({required this.cotizacion});

  String _fmt(double v) =>
      v.toStringAsFixed(v % 1 == 0 ? 0 : 2);

  String _duracion() {
    final m = cotizacion.duracionEstimada.inMinutes;
    return m >= 60 ? '${m ~/ 60}h ${m % 60}min' : '${m}min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(tariffViewModelProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehículo
          Row(
            children: [
              const Icon(Icons.local_shipping,
                  size: 16, color: AppTheme.azulPrimario),
              const SizedBox(width: AppTheme.spacingXs),
              Expanded(
                child: Text(
                  '${cotizacion.vehiculoNombre}  [${cotizacion.categoria.shortName}]',
                  style: TextStyle(
                    color: context.c.textoPrimario,
                    fontFamily: 'Courier New',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXs),

          // Distancia + duración
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
                    fontFamily: 'Courier New',
                    fontSize: 12,
                  ),
                ),
              ],
            ),

          const SizedBox(height: AppTheme.spacingLg),

          // Desglose
          GlassCard(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner × 2
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.naranjaPrimario.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusSm),
                    border: Border.all(
                        color: AppTheme.naranjaPrimario.withOpacity(0.4)),
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
                            fontFamily: 'Courier New',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
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
                  label: '+ ${(cotizacion.costoTiempo / cotizacion.costoKilometraje * 100).toStringAsFixed(0)}% tiempo × 2',
                  valor: cotizacion.costoTiempo,
                  sublabel: 'ida + vuelta',
                ),
                if (cotizacion.pesoKg > 0) ...[
                  const Divider(height: AppTheme.spacingMd),
                  _DesgloseLine(
                    label: '+ S/ ${_fmt(cotizacion.costoPeso / cotizacion.pesoKg / 2)} × ${cotizacion.pesoKg.toStringAsFixed(0)} kg × 2',
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
                          fontFamily: 'Courier New',
                          fontSize: 11,
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
                    const Text(
                      'Km · tiempo · peso  ×2  (ida + vuelta)',
                      style: TextStyle(
                        color: AppTheme.naranjaPrimario,
                        fontFamily: 'Courier New',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Acciones con fade in al aparecer
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

/// Botones GUARDAR / OLVIDAR con fade-in al montarse y fade-out al desmontarse
/// via AnimatedSwitcher del padre.
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
                  fontFamily: 'Courier New',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
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
                  fontFamily: 'Courier New',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
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
                  fontFamily: 'Courier New',
                  fontSize: 13,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  color: context.c.textoMuted,
                  fontFamily: 'Courier New',
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Text(
          'S/ ${_fmt(valor)}',
          style: TextStyle(
            color: context.c.textoSecundario,
            fontFamily: 'Courier New',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SinTarifaState extends StatelessWidget {
  final String distritoOrigen;
  final String distritoDestino;
  const _SinTarifaState({
    required this.distritoOrigen,
    required this.distritoDestino,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_outlined, size: 32, color: context.c.textoMuted),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            '[ SIN TARIFA ]',
            style: TextStyle(
              color: context.c.textoSecundario,
              fontFamily: 'Courier New',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: context.c.superficieCard,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
              border: Border.all(color: context.c.bordeInactivo),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distritos detectados:',
                  style: TextStyle(color: context.c.textoMuted, fontFamily: 'Courier New', fontSize: 10, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                Text(
                  '  origen  → "$distritoOrigen"',
                  style: const TextStyle(color: AppTheme.verdePrimario, fontFamily: 'Courier New', fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '  destino → "$distritoDestino"',
                  style: const TextStyle(color: AppTheme.error, fontFamily: 'Courier New', fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Carga las zonas desde\nCatálogo de Tarifas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.c.textoMuted,
              fontFamily: 'Courier New',
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PesoInputField extends ConsumerStatefulWidget {
  const _PesoInputField({super.key});

  @override
  ConsumerState<_PesoInputField> createState() => _PesoInputFieldState();
}

class _PesoInputFieldState extends ConsumerState<_PesoInputField> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Limpia el campo si el notifier resetea el peso a 0
    ref.listenManual(
      tariffInputNotifierProvider.select((i) => i.pesoKg),
      (prev, next) {
        if (next == 0.0 && _ctrl.text.isNotEmpty) _ctrl.clear();
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) {
        final kg = double.tryParse(v) ?? 0.0;
        ref.read(tariffInputNotifierProvider.notifier).setPeso(kg);
      },
      decoration: const InputDecoration(
        hintText: '0',
        labelText: 'Peso de la carga',
        prefixIcon: Icon(Icons.scale_outlined, size: 18),
        suffixText: 'kg',
      ),
    );
  }
}

class _OriginFijaWidget extends StatelessWidget {
  const _OriginFijaWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: context.c.bordeInactivo),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
        color: context.c.superficieCard,
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_checked,
              color: AppTheme.azulPrimario, size: 18),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BASE / ORIGEN',
                  style: TextStyle(
                    color: context.c.textoMuted,
                    fontFamily: 'Courier New',
                    fontSize: 9,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manuel de la Torre 191, Santa Anita',
                  style: TextStyle(
                    color: context.c.textoPrimario,
                    fontFamily: 'Courier New',
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline,
              size: 14, color: context.c.textoMuted),
        ],
      ),
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
              color: context.c.textoMuted,
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
      style: TextStyle(
        color: context.c.textoSecundario,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _RouteReadyState extends StatelessWidget {
  const _RouteReadyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 40, color: AppTheme.verdePrimario),
          const SizedBox(height: AppTheme.spacingMd),
          const Text(
            'Ruta cargada',
            style: TextStyle(
              color: AppTheme.verdePrimario,
              fontFamily: 'Courier New',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Presiona calcular tarifa',
            style: TextStyle(
              color: context.c.textoSecundario,
              fontFamily: 'Courier New',
              fontSize: 12,
            ),
          ),
        ],
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
          Icon(Icons.route_outlined, size: 48, color: context.c.textoMuted),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Ingresa el destino\npara calcular la tarifa',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.c.textoSecundario, height: 1.5),
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
          Text(mensaje, style: TextStyle(color: context.c.textoSecundario)),
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
  final CotizacionTarifario cotizacion;
  final ScrollController scrollController;
  const _ResultBottomSheet({
    required this.cotizacion,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: _CotizacionResult(cotizacion: cotizacion),
    );
  }
}

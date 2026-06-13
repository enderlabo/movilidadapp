import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tolls/presentation/viewmodels/toll_viewmodel.dart';
import '../../../tolls/domain/entities/toll.dart';
import '../../../tolls/domain/services/toll_matcher_service.dart';
import '../../../tolls/domain/usecases/process_route_tolls_usecase.dart';

/// Bottom sheet que aparece cuando hay peajes que requieren revisión.
/// La jefa puede confirmar o corregir los montos antes de calcular la tarifa.
class TollReviewSheet extends ConsumerWidget {
  const TollReviewSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tollMatchingViewModelProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: state.when(
        idle: () => const SizedBox.shrink(),
        processing: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        done: (result) => _TollReviewContent(result: result),
        error: (failure) => Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Text('Error: ${failure.userMessage}'),
        ),
      ),
    );
  }
}

class _TollReviewContent extends ConsumerWidget {
  final ProcessRouteTollsResult result;

  const _TollReviewContent({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(tollMatchingViewModelProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.grisMedium,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Row(
            children: [
              const Icon(Icons.toll_outlined, color: Colors.orange, size: 20),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Revisar peajes detectados',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (result.sinConfirmar.isNotEmpty)
                _Badge(
                  label: '${result.sinConfirmar.length} sin confirmar',
                  color: Colors.orange,
                ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingSm),

        // Explicación contextual
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Text(
            'Google Maps detectó estos peajes en la ruta. '
            'Los marcados en naranja no están confirmados en el catálogo. '
            'Corrígelos si el monto es incorrecto.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textoSecundario,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingMd),

        // Lista de peajes
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd),
            itemCount: result.matchResults.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTheme.spacingSm),
            itemBuilder: (_, i) => _TollReviewRow(
              matchResult: result.matchResults[i],
              snapshot: result.snapshots[i],
              onMontoChanged: (nuevoMonto) {
                vm.corregirMonto(
                  result.snapshots[i].tollId,
                  nuevoMonto,
                );
              },
            ),
          ),
        ),

        // Botón confirmar
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Confirmar peajes'),
            ),
          ),
        ),
      ],
    );
  }
}

class _TollReviewRow extends ConsumerStatefulWidget {
  final TollMatchResult matchResult;
  final TollSnapshot snapshot;
  final ValueChanged<double> onMontoChanged;

  const _TollReviewRow({
    required this.matchResult,
    required this.snapshot,
    required this.onMontoChanged,
  });

  @override
  ConsumerState<_TollReviewRow> createState() => _TollReviewRowState();
}

class _TollReviewRowState extends ConsumerState<_TollReviewRow> {
  late final TextEditingController _controller;
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.snapshot.montoUsado.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final requiereConfirmacion = widget.matchResult.requiereConfirmacion;
    final fueCorregido = widget.snapshot.fueCorregidoPorJefa;

    return GlassCard(
      child: Row(
        children: [
          // Estado del peaje
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fueCorregido
                  ? AppTheme.azulPrimario
                  : requiereConfirmacion
                      ? Colors.orange
                      : AppTheme.exito,
            ),
          ),

          const SizedBox(width: AppTheme.spacingMd),

          // Nombre del peaje
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.snapshot.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  requiereConfirmacion
                      ? 'Sin confirmar en catálogo'
                      : 'Catálogo confirmado',
                  style: TextStyle(
                    fontSize: 11,
                    color: requiereConfirmacion
                        ? Colors.orange
                        : AppTheme.exito,
                  ),
                ),
              ],
            ),
          ),

          // Editor de monto
          _editando
              ? SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      prefixText: 'S/ ',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    onSubmitted: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null && parsed >= 0) {
                        widget.onMontoChanged(parsed);
                      }
                      setState(() => _editando = false);
                    },
                  ),
                )
              : GestureDetector(
                  onTap: () => setState(() => _editando = true),
                  child: Row(
                    children: [
                      Text(
                        fmt.format(widget.snapshot.montoUsado),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: fueCorregido
                              ? AppTheme.azulPrimario
                              : AppTheme.textoPrimario,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_outlined,
                          size: 14, color: AppTheme.grisMedium),
                    ],
                  ),
                ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

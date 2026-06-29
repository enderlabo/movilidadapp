import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/tarifa_zona.dart';
import '../viewmodels/tarifas_viewmodel.dart';
import 'tarifa_form_screen.dart';

class TarifasScreen extends ConsumerWidget {
  const TarifasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarifasAsync = ref.watch(tarifasStreamProvider);
    final notifier = ref.read(tarifasProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('> TARIFAS'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context, null),
        backgroundColor: AppTheme.verdePrimario,
        foregroundColor: AppTheme.negro,
        icon: const Icon(Icons.add),
        label: const Text(
          'NUEVA TARIFA',
          style: TextStyle(
            fontFamily: 'Courier New',
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: tarifasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: AppTheme.error)),
        ),
        data: (tarifas) {
          if (tarifas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '[ SIN TARIFAS ]',
                    style: TextStyle(
                      color: context.c.textoSecundario,
                      fontSize: 18,
                      fontFamily: 'Courier New',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Crea tu primera tarifa con el botón +',
                    style: TextStyle(
                      color: context.c.textoMuted,
                      fontFamily: 'Courier New',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          // Agrupar por par de distritos
          final grupos = <String, List<TarifaZona>>{};
          for (final t in tarifas) {
            grupos.putIfAbsent(t.descripcionRuta, () => []).add(t);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: grupos.length,
            itemBuilder: (ctx, i) {
              final ruta = grupos.keys.elementAt(i);
              final items = grupos[ruta]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                    child: Text(
                      '// $ruta',
                      style: TextStyle(
                        color: context.c.textoSecundario,
                        fontFamily: 'Courier New',
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...items.map((t) => _TarifaCard(
                        tarifa: t,
                        onEdit: () => _abrirFormulario(context, t),
                        onDelete: () => _confirmarEliminar(context, t, notifier),
                      )),
                  const SizedBox(height: AppTheme.spacingMd),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _abrirFormulario(BuildContext context, TarifaZona? tarifa) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TarifaFormScreen(tarifa: tarifa)),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, TarifaZona tarifa, TarifasNotifier notifier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.c.superficieCard,
        title: Text(
          'Eliminar tarifa',
          style: TextStyle(color: context.c.textoPrimario, fontFamily: 'Courier New'),
        ),
        content: Text(
          '¿Eliminar tarifa para ${tarifa.descripcionRuta} - ${tarifa.categoria.displayName}?',
          style: TextStyle(
            color: context.c.textoSecundario,
            fontFamily: 'Courier New',
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCELAR', style: TextStyle(color: context.c.textoMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) notifier.eliminar(tarifa.id);
  }
}

class _TarifaCard extends StatelessWidget {
  final TarifaZona tarifa;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TarifaCard({
    required this.tarifa,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onEdit,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.bordeInactivo),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
            ),
            child: Text(
              tarifa.categoria.shortName,
              style: const TextStyle(
                color: AppTheme.verdePrimario,
                fontFamily: 'Courier New',
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              tarifa.precioDisplay,
              style: const TextStyle(
                color: AppTheme.verdePrimario,
                fontFamily: 'Courier New',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'incl. recojo',
            style: TextStyle(
              color: context.c.textoMuted,
              fontFamily: 'Courier New',
              fontSize: 11,
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18, color: context.c.textoSecundario),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/zona_tarifaria.dart';
import '../viewmodels/zonas_viewmodel.dart';
import 'zona_form_screen.dart';

class ZonasScreen extends ConsumerWidget {
  const ZonasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonasAsync = ref.watch(zonasStreamProvider);
    final notifierState = ref.watch(zonasNotifierProvider);
    final notifier = ref.read(zonasNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('> ZONAS DE TARIFA'),
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
          '+ NUEVA ZONA',
          style: TextStyle(
            fontFamily: 'Courier New',
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          zonasAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: AppTheme.error),
              ),
            ),
            data: (zonas) {
              if (zonas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '[ SIN ZONAS CONFIGURADAS ]',
                        style: TextStyle(
                          color: AppTheme.textoSecundario,
                          fontSize: 16,
                          fontFamily: 'Courier New',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      const Text(
                        'Carga las zonas iniciales para empezar',
                        style: TextStyle(
                          color: AppTheme.textoMuted,
                          fontFamily: 'Courier New',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                      ElevatedButton.icon(
                        onPressed: notifierState.isLoading
                            ? null
                            : () => notifier.seedDefault(),
                        icon: notifierState.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.negro,
                                ),
                              )
                            : const Icon(Icons.download_outlined, size: 18),
                        label: const Text('CARGAR ZONAS INICIALES'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                  80, // espacio para el FAB
                ),
                itemCount: zonas.length,
                itemBuilder: (ctx, i) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppTheme.spacingSm),
                  child: _ZonaCard(
                    zona: zonas[i],
                    onEdit: () => _abrirFormulario(context, zonas[i]),
                    onDelete: () =>
                        _confirmarEliminar(context, zonas[i], notifier),
                  ),
                ),
              );
            },
          ),
          // Overlay de carga para acciones del notifier
          if (notifierState.isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _abrirFormulario(BuildContext context, ZonaTarifaria? zona) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => ZonaFormScreen(zona: zona)),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    ZonaTarifaria zona,
    ZonasNotifier notifier,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.superficieCard,
        title: Text(
          'Eliminar ${zona.nombre}',
          style: const TextStyle(
            color: AppTheme.textoPrimario,
            fontFamily: 'Courier New',
          ),
        ),
        content: Text(
          '¿Desactivar ${zona.nombre}? Los distritos ya no tendrán tarifa asignada.',
          style: const TextStyle(
            color: AppTheme.textoSecundario,
            fontFamily: 'Courier New',
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: AppTheme.textoMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) notifier.eliminar(zona.id);
  }
}

class _ZonaCard extends StatelessWidget {
  final ZonaTarifaria zona;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ZonaCard({
    required this.zona,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge de zona
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.verdePrimario),
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSm),
                ),
                alignment: Alignment.center,
                child: Text(
                  zona.zona,
                  style: const TextStyle(
                    color: AppTheme.verdePrimario,
                    fontFamily: 'Courier New',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Nombre y precio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zona.nombre,
                      style: const TextStyle(
                        color: AppTheme.textoPrimario,
                        fontFamily: 'Courier New',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      zona.precioDisplay,
                      style: TextStyle(
                        color: zona.requiereCotizar
                            ? const Color(0xFFFF9800) // naranja/warning
                            : AppTheme.verdePrimario,
                        fontFamily: 'Courier New',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Acciones
              Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppTheme.textoSecundario,
                    ),
                    onPressed: onEdit,
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTheme.error,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),

          if (zona.distritos.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            const Divider(height: 1),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              zona.distritos.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textoMuted,
                fontFamily: 'Courier New',
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

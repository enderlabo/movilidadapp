import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/tarifa_config.dart';
import '../viewmodels/tarifa_config_viewmodel.dart';
import '../widgets/vehicle_selector.dart';

class InfoTarifasScreen extends ConsumerWidget {
  const InfoTarifasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(tarifaConfigNotifierProvider).valueOrNull ??
        TarifaConfig.defaults;
    final pct = (config.factorTiempo * 100).toStringAsFixed(0);
    final vehiculos = ref.watch(vehiculosProvider).valueOrNull ?? [];

    final colors = [AppTheme.azulPrimario, AppTheme.verdePrimario];
    final icons = [Icons.local_shipping_outlined, Icons.fire_truck_outlined];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de Tarifas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(label: 'TARIFAS VIGENTES'),
            const SizedBox(height: AppTheme.spacingMd),

            if (vehiculos.isEmpty)
              const Text(
                'Sin vehículos configurados',
                style: TextStyle(color: AppTheme.textoMuted, fontFamily: 'Courier New', fontSize: 13),
              )
            else
              for (int i = 0; i < vehiculos.length; i++) ...[
                _TarifaCard(
                  icon: icons[i % icons.length],
                  titulo: vehiculos[i].nombre,
                  tarifa: 'S/ ${config.tarifaPara(vehiculos[i].id).toStringAsFixed(0)}',
                  unidad: 'por km',
                  color: colors[i % colors.length],
                ),
                if (i < vehiculos.length - 1) const SizedBox(height: AppTheme.spacingMd),
              ],

            const SizedBox(height: AppTheme.spacingXl),
            const _SectionTitle(label: 'FACTORES ADICIONALES'),
            const SizedBox(height: AppTheme.spacingMd),

            GlassCard(
              child: Column(
                children: [
                  _FactorRow(
                    icon: Icons.access_time_outlined,
                    label: 'Factor tiempo',
                    valor: '+ $pct%',
                    detalle:
                        'Se aplica sobre el costo total de km.\nIncluye ~60 min entre salida del almacén y llegada al destino.',
                  ),
                  const Divider(height: AppTheme.spacingLg, color: AppTheme.bordeInactivo),
                  _FactorRow(
                    icon: Icons.scale_outlined,
                    label: 'Costo por kg',
                    valor: 'S/ ${config.tarifaPorKg.toStringAsFixed(2)}/kg',
                    detalle:
                        'Se suma al total según el peso declarado de la carga.',
                  ),
                  const Divider(height: AppTheme.spacingLg, color: AppTheme.bordeInactivo),
                  _FactorRow(
                    icon: Icons.repeat_outlined,
                    label: 'Entrega y recojo',
                    valor: '× 2',
                    detalle:
                        'El servicio incluye siempre ida y vuelta.\nLos km se multiplican × 2 antes de calcular.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),
            const _SectionTitle(label: 'FÓRMULA'),
            const SizedBox(height: AppTheme.spacingMd),

            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _FormulaLine(texto: 'costo_km  =  tarifa × km × 2'),
                  SizedBox(height: 6),
                  _FormulaLine(texto: 'tiempo    =  costo_km × 0.20'),
                  Divider(height: 20, color: AppTheme.bordeInactivo),
                  _FormulaLine(texto: 'TOTAL     =  costo_km + tiempo', highlight: true),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),
            const _SectionTitle(label: 'EJEMPLO'),
            const SizedBox(height: AppTheme.spacingMd),

            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehiculos.isNotEmpty ? vehiculos[0].nombre : 'Vehículo'} · 5 km de distancia',
                    style: TextStyle(
                      color: AppTheme.textoSecundario,
                      fontFamily: 'Courier New',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  const _EjemploLine(label: 'S/ 12 × 5 km × 2', valor: 'S/ 120.00'),
                  const _EjemploLine(label: '+ 20% tiempo', valor: 'S/ 24.00'),
                  const Divider(height: 16, color: AppTheme.bordeInactivo),
                  const _EjemploLine(
                    label: 'TOTAL',
                    valor: 'S/ 144.00',
                    highlight: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // Footer
            Center(
              child: Column(
                children: const [
                  Divider(color: AppTheme.bordeInactivo),
                  SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'Tarifario Movilidad',
                    style: TextStyle(
                      color: AppTheme.textoMuted,
                      fontFamily: 'Courier New',
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Desarrollado por: Elderson Laborit',
                    style: TextStyle(
                      color: AppTheme.verdePrimario,
                      fontFamily: 'Courier New',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMd),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.grisDark,
        fontFamily: 'Courier New',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _TarifaCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String tarifa;
  final String unidad;
  final Color color;

  const _TarifaCard({
    required this.icon,
    required this.titulo,
    required this.tarifa,
    required this.unidad,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                color: AppTheme.textoPrimario,
                fontFamily: 'Courier New',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: tarifa,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'Courier New',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' $unidad',
                  style: const TextStyle(
                    color: AppTheme.textoMuted,
                    fontFamily: 'Courier New',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final String detalle;

  const _FactorRow({
    required this.icon,
    required this.label,
    required this.valor,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.azulPrimario, size: 20),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textoPrimario,
                        fontFamily: 'Courier New',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    valor,
                    style: const TextStyle(
                      color: AppTheme.azulPrimario,
                      fontFamily: 'Courier New',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                detalle,
                style: const TextStyle(
                  color: AppTheme.textoMuted,
                  fontFamily: 'Courier New',
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormulaLine extends StatelessWidget {
  final String texto;
  final bool highlight;
  const _FormulaLine({required this.texto, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        color: highlight ? AppTheme.verdePrimario : AppTheme.textoSecundario,
        fontFamily: 'Courier New',
        fontSize: highlight ? 14 : 13,
        fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
      ),
    );
  }
}

class _EjemploLine extends StatelessWidget {
  final String label;
  final String valor;
  final bool highlight;
  const _EjemploLine({
    required this.label,
    required this.valor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: highlight ? AppTheme.verdePrimario : AppTheme.textoSecundario,
                fontFamily: 'Courier New',
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: highlight ? AppTheme.verdePrimario : AppTheme.textoSecundario,
              fontFamily: 'Courier New',
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

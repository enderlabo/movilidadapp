import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/app_router.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Información sobre el App'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── RASTREO GPS ──────────────────────────────────────────
            const _SectionTitle(label: 'RASTREO GPS'),
            const SizedBox(height: AppTheme.spacingMd),
            const _GpsPortalCard(),

            const SizedBox(height: AppTheme.spacingXl),

            // ── RUTAS EN EL MAPA ─────────────────────────────────────
            const _SectionTitle(label: 'RUTAS EN EL MAPA'),
            const SizedBox(height: AppTheme.spacingMd),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    leading: _LinePreview(color: AppTheme.naranjaPrimario, strokeWidth: 5),
                    titulo: 'Ruta principal',
                    detalle: 'Línea gruesa — la opción más rápida calculada por Maps para el trayecto actual.',
                  ),
                  const Divider(height: AppTheme.spacingLg, color: AppTheme.bordeInactivo),
                  _InfoRow(
                    leading: _LinePreview(color: AppTheme.naranjaPrimario.withValues(alpha: 0.45), strokeWidth: 2.5),
                    titulo: 'Rutas alternativas',
                    detalle: 'Línea delgada — caminos alternativos. Pueden ser más largos pero evitar tráfico.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // ── COMBUSTIBLE Y COLOR ───────────────────────────────────
            const _SectionTitle(label: 'COMBUSTIBLE Y COLOR DE RUTA'),
            const SizedBox(height: AppTheme.spacingMd),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    leading: _ColorDot(color: AppTheme.exito),
                    titulo: 'GNV — Dongfeng DF-814 (CCK-886)',
                    detalle: 'Rutas en verde. Gas Natural Vehicular: el costo por kilómetro es mucho más barato que la gasolina. Ideal para zonas comerciales y distancias largas.',
                    accentColor: AppTheme.exito,
                  ),
                  const Divider(height: AppTheme.spacingLg, color: AppTheme.bordeInactivo),
                  _InfoRow(
                    leading: _ColorDot(color: AppTheme.naranjaPrimario),
                    titulo: 'Gasolina — Forland 190 (BSL-831)',
                    detalle: 'Rutas en naranja. Mayor maniobrabilidad en calles estrechas. Preferido en zonas residenciales con carga ligera (menos de 1,500 kg).',
                    accentColor: AppTheme.naranjaPrimario,
                  ),
                  const Divider(height: AppTheme.spacingLg, color: AppTheme.bordeInactivo),
                  _InfoRow(
                    leading: const _ColorDot(color: Color(0xFF9C6FFF)),
                    titulo: 'Alta velocidad',
                    detalle: 'Rutas en morado. La ruta usa Vía de Evitamiento, Panamericana Norte/Sur o Carretera Central — vías sin restricciones de circulación.',
                    accentColor: const Color(0xFF9C6FFF),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // ── ZONAS DE LIMA ─────────────────────────────────────────
            const _SectionTitle(label: 'ZONAS DE LIMA Y VEHÍCULO RECOMENDADO'),
            const SizedBox(height: AppTheme.spacingMd),
            const _ZonaCard(
              color: Color(0xFF5B9BD5),
              icon: Icons.home_outlined,
              zona: 'Residencial / Financiero',
              vehiculoLigero: 'Forland 190',
              vehiculoPesado: 'Dongfeng DF-814',
              razon: 'Calles estrechas y alta presencia de serenazgo. El Forland es más maniobrable y fácil de estacionar.',
              distritos: 'San Borja · Miraflores · San Isidro · Magdalena · Jesús María · Surco · Barranco · San Miguel · Pueblo Libre · La Molina',
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const _ZonaCard(
              color: AppTheme.exito,
              icon: Icons.store_outlined,
              zona: 'Comercial / Industrial',
              vehiculoLigero: 'Dongfeng DF-814',
              vehiculoPesado: 'Dongfeng DF-814',
              razon: 'Avenidas anchas aptas para camiones. El GNV del Dongfeng reduce costos drásticamente en rutas de alto tránsito comercial.',
              distritos: 'Santa Anita · Ate · San Luis · La Victoria · Cercado de Lima · Breña · Rímac · El Agustino · San Juan de Lurigancho',
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const _ZonaCard(
              color: AppTheme.naranjaPrimario,
              icon: Icons.location_city_outlined,
              zona: 'Zona Periférica / Conos',
              vehiculoLigero: 'Dongfeng DF-814',
              vehiculoPesado: 'Dongfeng DF-814',
              razon: 'Distancias largas que justifican usar GNV. El Forland solo se prefiere si hay pasajes sin asfaltar o cerros muy empinados.',
              distritos: 'Comas · Carabayllo · Independencia · Los Olivos · San Juan de Miraflores · Villa El Salvador · Villa María del Triunfo · Chorrillos · Lurín · Puente Piedra · Ventanilla',
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const _ZonaCard(
              color: Color(0xFF9C6FFF),
              icon: Icons.speed_outlined,
              zona: 'Ruta de Alta Velocidad',
              vehiculoLigero: 'Dongfeng DF-814',
              vehiculoPesado: 'Dongfeng DF-814',
              razon: 'Vías libres de restricciones vehiculares. El motor a gas rinde al máximo en trayectos directos a alta velocidad.',
              distritos: 'Detectado automáticamente cuando Maps usa:\nVía de Evitamiento · Panamericana Norte · Panamericana Sur · Carretera Central',
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // ── REGLAS DE ORO ─────────────────────────────────────────
            const _SectionTitle(label: 'REGLAS DE ORO'),
            const SizedBox(height: AppTheme.spacingMd),
            GlassCard(
              child: Column(
                children: const [
                  _ReglaOro(
                    numero: '1',
                    titulo: 'Regla de las 1,500 kg',
                    descripcion:
                        'Si la carga pesa menos de 1,500 kg y el destino es una zona residencial, usa el Forland 190 por su maniobrabilidad y facilidad para estacionar en calles angostas.',
                    color: Color(0xFF5B9BD5),
                  ),
                  Divider(height: AppTheme.spacingLg, color: AppTheme.bordeInactivo),
                  _ReglaOro(
                    numero: '2',
                    titulo: 'Regla del ahorro GNV',
                    descripcion:
                        'Si la ruta permite libre tránsito de camiones (como Santa Anita, Ate o San Juan de Lurigancho), usa el Dongfeng DF-814 aunque la carga sea poca. El costo por km en GNV es mucho más barato que la gasolina.',
                    color: AppTheme.exito,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // ── TARIFAS VIGENTES ──────────────────────────────────────
            const _SectionTitle(label: 'TARIFAS VIGENTES'),
            const SizedBox(height: AppTheme.spacingMd),

            if (vehiculos.isEmpty)
              const Text('Sin vehículos configurados')
            else
              for (int i = 0; i < vehiculos.length; i++) ...[
                _TarifaCard(
                  icon: i == 0 ? Icons.local_shipping_outlined : Icons.fire_truck_outlined,
                  titulo: vehiculos[i].nombre,
                  tarifa: 'S/ ${config.tarifaPara(vehiculos[i].id).toStringAsFixed(0)}',
                  color: i == 0 ? AppTheme.naranjaPrimario : AppTheme.exito,
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
                    detalle: 'Se aplica sobre el costo total de km. Incluye el tiempo entre salida del almacén y llegada al destino.',
                  ),
                  const Divider(height: AppTheme.spacingLg, color: AppTheme.bordeInactivo),
                  _FactorRow(
                    icon: Icons.scale_outlined,
                    label: 'Costo por kg',
                    valor: 'S/ ${config.tarifaPorKg.toStringAsFixed(2)}/kg',
                    detalle: 'Se suma al total según el peso declarado de la carga.',
                  ),
                  const Divider(height: AppTheme.spacingLg, color: AppTheme.bordeInactivo),
                  _FactorRow(
                    icon: Icons.repeat_outlined,
                    label: 'Entrega y recojo',
                    valor: '× 2',
                    detalle: 'El servicio siempre incluye ida y vuelta. Los km se multiplican × 2 antes de calcular.',
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
                  SizedBox(height: 8),
                  _FormulaLine(texto: 'tiempo    =  costo_km × 0.20'),
                  Divider(height: 24, color: AppTheme.bordeInactivo),
                  _FormulaLine(texto: 'TOTAL  =  costo_km + tiempo', highlight: true),
                ],
              ),
            ),

            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  const Divider(color: AppTheme.bordeInactivo),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'Tarifario Movilidad',
                    style: TextStyle(color: context.c.textoMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Desarrollado por: Elderson Laborit',
                    style: TextStyle(
                      color: AppTheme.verdePrimario,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sección título ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          color: AppTheme.naranjaPrimario,
          margin: const EdgeInsets.only(right: 10),
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.naranjaPrimario,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tarjeta del portal GPS ────────────────────────────────────────────────────

class _GpsPortalCard extends StatelessWidget {
  const _GpsPortalCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.gps),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.azulPrimario.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.azulPrimario, width: 2),
              ),
              child: const Icon(Icons.gps_fixed,
                  color: AppTheme.azulPrimario, size: 22),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portal GPS Alarma Inteligente',
                    style: TextStyle(
                      color: context.c.textoPrimario,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Abre el rastreo en vivo de las unidades dentro de la app. '
                    'Inicias sesión una vez y la sesión queda guardada.',
                    style: TextStyle(
                      color: context.c.textoSecundario,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Icon(Icons.chevron_right, color: context.c.textoMuted),
          ],
        ),
      ),
    );
  }
}

// ── Muestra visual de línea de ruta ──────────────────────────────────────────

class _LinePreview extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  const _LinePreview({required this.color, required this.strokeWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(painter: _LinePainter(color: color, strokeWidth: strokeWidth)),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _LinePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ── Punto de color ────────────────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
      ),
    );
  }
}

// ── Fila informativa ─────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final Widget leading;
  final String titulo;
  final String detalle;
  final Color? accentColor;

  const _InfoRow({
    required this.leading,
    required this.titulo,
    required this.detalle,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 4), child: leading),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: accentColor ?? context.c.textoPrimario,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detalle,
                style: TextStyle(
                  color: context.c.textoSecundario,
                  fontSize: 16,
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

// ── Zona card ─────────────────────────────────────────────────────────────────

class _ZonaCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String zona;
  final String vehiculoLigero;
  final String vehiculoPesado;
  final String razon;
  final String distritos;

  const _ZonaCard({
    required this.color,
    required this.icon,
    required this.zona,
    required this.vehiculoLigero,
    required this.vehiculoPesado,
    required this.razon,
    required this.distritos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  zona,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _CargaChip(label: 'Menos de\n1,500 kg', vehiculo: vehiculoLigero, color: color)),
              const SizedBox(width: 10),
              Expanded(child: _CargaChip(label: '1,500 kg\no más', vehiculo: vehiculoPesado, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            razon,
            style: TextStyle(
              color: context.c.textoSecundario,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            distritos,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _CargaChip extends StatelessWidget {
  final String label;
  final String vehiculo;
  final Color color;

  const _CargaChip({
    required this.label,
    required this.vehiculo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            vehiculo,
            style: TextStyle(
              color: context.c.textoPrimario,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Regla de oro ──────────────────────────────────────────────────────────────

class _ReglaOro extends StatelessWidget {
  final String numero;
  final String titulo;
  final String descripcion;
  final Color color;

  const _ReglaOro({
    required this.numero,
    required this.titulo,
    required this.descripcion,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            numero,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                descripcion,
                style: TextStyle(
                  color: context.c.textoSecundario,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tarifa card ───────────────────────────────────────────────────────────────

class _TarifaCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String tarifa;
  final Color color;

  const _TarifaCard({
    required this.icon,
    required this.titulo,
    required this.tarifa,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                color: context.c.textoPrimario,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            tarifa,
            style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Text(
            'por km',
            style: TextStyle(color: context.c.textoMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Factor row ────────────────────────────────────────────────────────────────

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
        Icon(icon, color: AppTheme.azulPrimario, size: 22),
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
                      style: TextStyle(
                        color: context.c.textoPrimario,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    valor,
                    style: const TextStyle(
                      color: AppTheme.azulPrimario,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                detalle,
                style: TextStyle(
                  color: context.c.textoMuted,
                  fontSize: 16,
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

// ── Fórmula ───────────────────────────────────────────────────────────────────

class _FormulaLine extends StatelessWidget {
  final String texto;
  final bool highlight;
  const _FormulaLine({required this.texto, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        color: highlight ? AppTheme.verdePrimario : context.c.textoSecundario,
        fontSize: highlight ? 18 : 16,
        fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
        height: 1.4,
      ),
    );
  }
}

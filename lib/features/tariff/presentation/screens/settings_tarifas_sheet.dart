import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/tarifa_config.dart';
import '../viewmodels/tarifa_config_viewmodel.dart';
import '../widgets/vehicle_selector.dart';

Future<void> mostrarSettingsTarifas(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends ConsumerStatefulWidget {
  const _SettingsSheet();

  @override
  ConsumerState<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<_SettingsSheet> {
  // Tarifa por vehículo: vehicle.id → controller
  final _vehicleControllers = <String, TextEditingController>{};
  final _tiempo = TextEditingController();
  final _pesoKg = TextEditingController();
  bool _guardando = false;
  List<Vehicle> _vehiculos = [];

  @override
  void initState() {
    super.initState();
    final config = ref.read(tarifaConfigNotifierProvider).valueOrNull ??
        TarifaConfig.defaults;
    _tiempo.text = (config.factorTiempo * 100).toStringAsFixed(0);
    _pesoKg.text = config.tarifaPorKg.toStringAsFixed(2);

    _vehiculos = ref.read(vehiculosProvider).valueOrNull ?? [];
    for (final v in _vehiculos) {
      _vehicleControllers[v.id] = TextEditingController(
        text: config.tarifaPara(v.id).toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    for (final ctrl in _vehicleControllers.values) {
      ctrl.dispose();
    }
    _tiempo.dispose();
    _pesoKg.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final tarifasPorVehiculo = <String, double>{};
    for (final v in _vehiculos) {
      final valor =
          double.tryParse(_vehicleControllers[v.id]?.text.trim() ?? '');
      if (valor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa valores numéricos válidos')),
        );
        return;
      }
      tarifasPorVehiculo[v.id] = valor;
    }

    final tiempo = double.tryParse(_tiempo.text.trim());
    final pesoKg = double.tryParse(_pesoKg.text.trim());
    if (tiempo == null || pesoKg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa valores numéricos válidos')),
      );
      return;
    }

    setState(() => _guardando = true);
    await ref.read(tarifaConfigNotifierProvider.notifier).guardar(
          TarifaConfig(
            tarifasPorVehiculo: tarifasPorVehiculo,
            tarifaDefault:
                tarifasPorVehiculo.values.firstOrNull ?? TarifaConfig.defaults.tarifaDefault,
            factorTiempo: tiempo / 100,
            tarifaPorKg: pesoKg,
          ),
        );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarifas actualizadas'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingLg + bottom,
      ),
      decoration: BoxDecoration(
        color: context.c.superficieCard,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        border: Border.all(color: context.c.bordeInactivo),
        boxShadow: [
          BoxShadow(color: context.c.naranjaGlow, blurRadius: 20, spreadRadius: 0),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.settings_outlined,
                    color: AppTheme.verdePrimario, size: 20),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    'Configurar tarifas',
                    style: TextStyle(
                      color: context.c.textoPrimario,
                      fontFamily: 'Courier New',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                  color: context.c.textoMuted,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Campo por cada vehículo
            if (_vehiculos.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: Text(
                  'No hay vehículos cargados',
                  style: TextStyle(
                    color: context.c.textoMuted,
                    fontFamily: 'Courier New',
                    fontSize: 13,
                  ),
                ),
              )
            else
              for (final v in _vehiculos) ...[
                _ConfigField(
                  controller: _vehicleControllers[v.id]!,
                  label: 'Costo km — ${v.nombre}',
                  suffix: 'S/ / km',
                  icon: Icons.local_shipping_outlined,
                ),
                const SizedBox(height: AppTheme.spacingMd),
              ],

            _ConfigField(
              controller: _tiempo,
              label: 'Factor tiempo',
              suffix: '%',
              icon: Icons.access_time_outlined,
            ),

            const SizedBox(height: AppTheme.spacingMd),

            _ConfigField(
              controller: _pesoKg,
              label: 'Costo por kg de carga',
              suffix: 'S/ / kg',
              icon: Icons.scale_outlined,
            ),

            const SizedBox(height: AppTheme.spacingXl),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_guardando ? 'Guardando...' : 'Guardar configuración'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.verdePrimario,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;

  const _ConfigField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon, size: 18),
        suffixStyle: TextStyle(
          color: context.c.textoMuted,
          fontFamily: 'Courier New',
          fontSize: 13,
        ),
      ),
    );
  }
}

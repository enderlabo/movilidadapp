import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/tarifa_config.dart';
import '../viewmodels/tarifa_config_viewmodel.dart';
import '../widgets/vehicle_selector.dart';

/// Bottom sheet para parametrizar tarifas desde la UI.
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
  final _pequeno = TextEditingController();
  final _grande = TextEditingController();
  final _tiempo = TextEditingController();
  final _pesoKg = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(tarifaConfigNotifierProvider).valueOrNull ??
        TarifaConfig.defaults;
    _pequeno.text = config.tarifaPequeno.toStringAsFixed(2);
    _grande.text = config.tarifaGrande.toStringAsFixed(2);
    _tiempo.text = (config.factorTiempo * 100).toStringAsFixed(0);
    _pesoKg.text = config.tarifaPorKg.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _pequeno.dispose();
    _grande.dispose();
    _tiempo.dispose();
    _pesoKg.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final pequeno = double.tryParse(_pequeno.text.trim());
    final grande = double.tryParse(_grande.text.trim());
    final tiempo = double.tryParse(_tiempo.text.trim());
    final pesoKg = double.tryParse(_pesoKg.text.trim());

    if (pequeno == null || grande == null || tiempo == null || pesoKg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa valores numéricos válidos')),
      );
      return;
    }

    setState(() => _guardando = true);
    await ref.read(tarifaConfigNotifierProvider.notifier).guardar(
          TarifaConfig(
            tarifaPequeno: pequeno,
            tarifaGrande: grande,
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
    final vehiculos = ref.watch(vehiculosProvider).valueOrNull ?? [];
    final nombre0 = vehiculos.isNotEmpty ? vehiculos[0].nombre : 'Vehículo 1';
    final nombre1 = vehiculos.length > 1  ? vehiculos[1].nombre : 'Vehículo 2';

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingLg + bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.superficieCard,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        border: Border.all(color: AppTheme.bordeInactivo),
        boxShadow: [
          BoxShadow(color: AppTheme.verdeGlow, blurRadius: 20, spreadRadius: 0),
        ],
      ),
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
              const Expanded(
                child: Text(
                  'Configurar tarifas',
                  style: TextStyle(
                    color: AppTheme.textoPrimario,
                    fontFamily: 'Courier New',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => Navigator.pop(context),
                color: AppTheme.textoMuted,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLg),

          _ConfigField(
            controller: _pequeno,
            label: 'Costo km — $nombre0',
            suffix: 'S/ / km',
            icon: Icons.local_shipping_outlined,
          ),

          const SizedBox(height: AppTheme.spacingMd),

          _ConfigField(
            controller: _grande,
            label: 'Costo km — $nombre1',
            suffix: 'S/ / km',
            icon: Icons.fire_truck_outlined,
          ),

          const SizedBox(height: AppTheme.spacingMd),

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
        suffixStyle: const TextStyle(
          color: AppTheme.textoMuted,
          fontFamily: 'Courier New',
          fontSize: 13,
        ),
      ),
    );
  }
}

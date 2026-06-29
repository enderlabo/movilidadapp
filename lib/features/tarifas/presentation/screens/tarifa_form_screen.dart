import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/tarifa_zona.dart';
import '../viewmodels/tarifas_viewmodel.dart';

const _distritosLima = [
  'Ate', 'Barranco', 'Breña', 'Carabayllo', 'Chorrillos', 'Cieneguilla',
  'Comas', 'El Agustino', 'Independencia', 'Jesús María', 'La Molina',
  'La Victoria', 'Lima', 'Lince', 'Los Olivos', 'Lurigancho', 'Lurín',
  'Magdalena del Mar', 'Miraflores', 'Pachacámac', 'Pueblo Libre',
  'Puente Piedra', 'Rímac', 'San Borja', 'San Isidro',
  'San Juan de Lurigancho', 'San Juan de Miraflores', 'San Luis',
  'San Martín de Porres', 'San Miguel', 'Santa Anita', 'Santiago de Surco',
  'Surquillo', 'Villa El Salvador', 'Villa María del Triunfo',
];

class TarifaFormScreen extends ConsumerStatefulWidget {
  final TarifaZona? tarifa;

  const TarifaFormScreen({super.key, this.tarifa});

  @override
  ConsumerState<TarifaFormScreen> createState() => _TarifaFormScreenState();
}

class _TarifaFormScreenState extends ConsumerState<TarifaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();
  final _precioMinController = TextEditingController();
  final _precioMaxController = TextEditingController();

  String? _distritoOrigen;
  String? _distritoDestino;
  CategoriaVehiculo _categoria = CategoriaVehiculo.pequeno;
  bool _mismoDistrito = false;

  bool get _esIntraDistrito => _mismoDistrito || (_distritoOrigen != null && _distritoOrigen == _distritoDestino);

  @override
  void initState() {
    super.initState();
    final t = widget.tarifa;
    if (t != null) {
      _distritoOrigen = t.distritoOrigen;
      _distritoDestino = t.distritoDestino;
      _categoria = t.categoria;
      _mismoDistrito = t.esIntraDistrito;
      if (t.esIntraDistrito) {
        _precioMinController.text = t.precioMinSoles?.toStringAsFixed(0) ?? '';
        _precioMaxController.text = t.precioMaxSoles?.toStringAsFixed(0) ?? '';
      } else {
        _precioController.text = t.precioSoles.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _precioController.dispose();
    _precioMinController.dispose();
    _precioMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tarifa != null;
    final notifierState = ref.watch(tarifasProvider);

    ref.listen<AsyncValue<void>>(tarifasProvider, (_, next) {
      next.whenOrNull(
        data: (_) => Navigator.of(context).pop(),
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '> EDITAR TARIFA' : '> NUEVA TARIFA'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            // ── Origen ──
            const _FieldLabel(label: 'DISTRITO ORIGEN'),
            const SizedBox(height: AppTheme.spacingSm),
            _DistritoDropdown(
              value: _distritoOrigen,
              hint: 'Selecciona distrito origen',
              onChanged: (v) => setState(() {
                _distritoOrigen = v;
                if (_mismoDistrito) _distritoDestino = v;
              }),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // ── Mismo distrito checkbox ──
            GestureDetector(
              onTap: () => setState(() {
                _mismoDistrito = !_mismoDistrito;
                if (_mismoDistrito) _distritoDestino = _distritoOrigen;
              }),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _mismoDistrito,
                      onChanged: (v) => setState(() {
                        _mismoDistrito = v ?? false;
                        if (_mismoDistrito) _distritoDestino = _distritoOrigen;
                      }),
                      activeColor: AppTheme.verdePrimario,
                      checkColor: AppTheme.negro,
                      side: const BorderSide(color: AppTheme.bordeInactivo),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    'Mismo distrito (intra-distrital)',
                    style: TextStyle(
                      color: context.c.textoSecundario,
                      fontFamily: 'Courier New',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // ── Destino ──
            const _FieldLabel(label: 'DISTRITO DESTINO'),
            const SizedBox(height: AppTheme.spacingSm),
            _DistritoDropdown(
              value: _esIntraDistrito ? _distritoOrigen : _distritoDestino,
              hint: 'Selecciona distrito destino',
              enabled: !_mismoDistrito,
              onChanged: _mismoDistrito ? null : (v) => setState(() => _distritoDestino = v),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Categoria ──
            const _FieldLabel(label: 'TIPO DE CAMIÓN'),
            const SizedBox(height: AppTheme.spacingSm),
            SegmentedButton<CategoriaVehiculo>(
              segments: CategoriaVehiculo.values
                  .map((c) => ButtonSegment(
                        value: c,
                        label: Text(
                          c.shortName,
                          style: const TextStyle(
                            fontFamily: 'Courier New',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ))
                  .toList(),
              selected: {_categoria},
              onSelectionChanged: (s) => setState(() => _categoria = s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.verdeTenue;
                  }
                  return AppTheme.superficieMid;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.verdePrimario;
                  }
                  return context.c.textoMuted;
                }),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: AppTheme.bordeInactivo),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Precio ──
            if (_esIntraDistrito) ...[
              const _FieldLabel(label: 'RANGO DE PRECIO (S/)'),
              const SizedBox(height: AppTheme.spacingSm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioMinController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: context.c.textoPrimario,
                        fontFamily: 'Courier New',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Mínimo S/',
                        labelStyle: TextStyle(color: context.c.textoMuted, fontFamily: 'Courier New', fontSize: 12),
                      ),
                      validator: (v) {
                        if (_esIntraDistrito && (v == null || v.isEmpty)) return 'Requerido';
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Número inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: TextFormField(
                      controller: _precioMaxController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: context.c.textoPrimario,
                        fontFamily: 'Courier New',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Máximo S/',
                        labelStyle: TextStyle(color: context.c.textoMuted, fontFamily: 'Courier New', fontSize: 12),
                      ),
                      validator: (v) {
                        if (_esIntraDistrito && (v == null || v.isEmpty)) return 'Requerido';
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Número inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              const _FieldLabel(label: 'PRECIO (S/)'),
              const SizedBox(height: AppTheme.spacingSm),
              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: context.c.textoPrimario,
                  fontFamily: 'Courier New',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  prefixText: 'S/ ',
                  prefixStyle: TextStyle(
                    color: AppTheme.verdePrimario,
                    fontFamily: 'Courier New',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) return 'Número inválido';
                  return null;
                },
              ),
            ],

            const SizedBox(height: AppTheme.spacingXl),

            // ── Guardar ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: notifierState.isLoading ? null : _guardar,
                child: notifierState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.negro,
                        ),
                      )
                    : const Text('GUARDAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (_distritoOrigen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el distrito origen')),
      );
      return;
    }
    final distritoDestino = _mismoDistrito ? _distritoOrigen! : _distritoDestino;
    if (distritoDestino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el distrito destino')),
      );
      return;
    }

    final esIntra = _distritoOrigen == distritoDestino;
    final double precioMin = esIntra ? double.parse(_precioMinController.text) : 0;
    final double precioMax = esIntra ? double.parse(_precioMaxController.text) : 0;
    final double precio = esIntra
        ? ((precioMin + precioMax) / 2)
        : double.parse(_precioController.text);

    final tarifa = TarifaZona(
      id: widget.tarifa?.id ?? const Uuid().v4(),
      distritoOrigen: _distritoOrigen!,
      distritoDestino: distritoDestino,
      categoria: _categoria,
      precioSoles: precio,
      precioMinSoles: esIntra ? precioMin : null,
      precioMaxSoles: esIntra ? precioMax : null,
    );

    ref.read(tarifasProvider.notifier).guardar(tarifa);
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.c.textoSecundario,
        fontFamily: 'Courier New',
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DistritoDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final bool enabled;
  final ValueChanged<String?>? onChanged;

  const _DistritoDropdown({
    required this.value,
    required this.hint,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      hint: Text(
        hint,
        style: TextStyle(color: context.c.textoMuted, fontFamily: 'Courier New', fontSize: 13),
      ),
      dropdownColor: context.c.superficieCard,
      style: TextStyle(color: context.c.textoPrimario, fontFamily: 'Courier New', fontSize: 13),
      decoration: InputDecoration(
        enabled: enabled,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
          borderSide: BorderSide(color: context.c.textoMuted),
        ),
      ),
      items: _distritosLima
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}

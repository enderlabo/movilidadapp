import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/zona_tarifaria.dart';
import '../viewmodels/zonas_viewmodel.dart';

class ZonaFormScreen extends ConsumerStatefulWidget {
  final ZonaTarifaria? zona;

  const ZonaFormScreen({super.key, this.zona});

  @override
  ConsumerState<ZonaFormScreen> createState() => _ZonaFormScreenState();
}

class _ZonaFormScreenState extends ConsumerState<ZonaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _zonaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _distritosController = TextEditingController();
  final _precioMinController = TextEditingController();
  final _precioMaxController = TextEditingController();

  bool _requiereCotizar = false;

  @override
  void initState() {
    super.initState();
    final z = widget.zona;
    if (z != null) {
      _zonaController.text = z.zona;
      _nombreController.text = z.nombre;
      _distritosController.text = z.distritos.join(', ');
      _requiereCotizar = z.requiereCotizar;
      if (z.precioMinSoles != null) {
        _precioMinController.text = z.precioMinSoles!.toStringAsFixed(0);
      }
      if (z.precioMaxSoles != null) {
        _precioMaxController.text = z.precioMaxSoles!.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _zonaController.dispose();
    _nombreController.dispose();
    _distritosController.dispose();
    _precioMinController.dispose();
    _precioMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.zona != null;
    final notifierState = ref.watch(zonasNotifierProvider);

    ref.listen<AsyncValue<void>>(zonasNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) => Navigator.of(context).pop(),
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '> EDITAR ZONA' : '> NUEVA ZONA'),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            // ── Letra de zona ──
            const _FieldLabel(label: 'ZONA (letra)'),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _zonaController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 2,
              style: const TextStyle(
                color: AppTheme.verdePrimario,
                fontFamily: 'Courier New',
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: 'A',
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                return null;
              },
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // ── Nombre ──
            const _FieldLabel(label: 'NOMBRE'),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _nombreController,
              style: TextStyle(
                color: context.c.textoPrimario,
                fontFamily: 'Courier New',
              ),
              decoration: const InputDecoration(
                hintText: 'Zona A',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                return null;
              },
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // ── Distritos ──
            const _FieldLabel(label: 'DISTRITOS'),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _distritosController,
              minLines: 3,
              maxLines: 6,
              style: TextStyle(
                color: context.c.textoPrimario,
                fontFamily: 'Courier New',
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                hintText: 'Ate, El Agustino, San Luis',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Requiere cotizar ──
            GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'REQUIERE COTIZAR',
                    style: TextStyle(
                      color: context.c.textoSecundario,
                      fontFamily: 'Courier New',
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Switch(
                    value: _requiereCotizar,
                    onChanged: (v) => setState(() => _requiereCotizar = v),
                    activeThumbColor: AppTheme.verdePrimario,
                    activeTrackColor: AppTheme.verdeTenue,
                    inactiveThumbColor: context.c.textoMuted,
                    inactiveTrackColor: context.c.superficieMid,
                  ),
                ],
              ),
            ),

            // ── Precio (si no requiere cotizar) ──
            if (!_requiereCotizar) ...[
              const SizedBox(height: AppTheme.spacingMd),
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
                        labelStyle: TextStyle(
                          color: context.c.textoMuted,
                          fontFamily: 'Courier New',
                          fontSize: 12,
                        ),
                      ),
                      validator: (v) {
                        if (!_requiereCotizar) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (double.tryParse(v) == null) {
                            return 'Número inválido';
                          }
                        }
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
                        labelStyle: TextStyle(
                          color: context.c.textoMuted,
                          fontFamily: 'Courier New',
                          fontSize: 12,
                        ),
                      ),
                      validator: (v) {
                        if (!_requiereCotizar) {
                          if (v == null || v.isEmpty) return 'Requerido';
                          if (double.tryParse(v) == null) {
                            return 'Número inválido';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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

    // Parsear distritos: split por coma o nueva línea
    final distritosRaw = _distritosController.text;
    final distritos = distritosRaw
        .split(RegExp(r'[,\n]'))
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();

    final zona = ZonaTarifaria(
      id: widget.zona?.id ?? const Uuid().v4(),
      zona: _zonaController.text.trim().toUpperCase(),
      nombre: _nombreController.text.trim(),
      distritos: distritos,
      requiereCotizar: _requiereCotizar,
      precioMinSoles:
          _requiereCotizar ? null : double.tryParse(_precioMinController.text),
      precioMaxSoles:
          _requiereCotizar ? null : double.tryParse(_precioMaxController.text),
    );

    ref.read(zonasNotifierProvider.notifier).guardar(zona);
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

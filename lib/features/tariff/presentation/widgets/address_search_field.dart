import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection/injection_container.dart';
import '../../../routes/domain/entities/route.dart';
import '../../../routes/domain/repositories/i_route_repository.dart';

part 'address_search_field.g.dart';

/// Provider del repositorio de rutas — se registra en InjectionContainer
@riverpod
IRouteRepository routeRepository(Ref ref) {
  return sl<IRouteRepository>();
}

/// Campo de búsqueda de dirección con autocompletado de Google Places.
class AddressSearchField extends ConsumerStatefulWidget {
  final String hint;
  final IconData icon;
  final Color iconColor;
  final ValueChanged<Waypoint> onWaypointSelected;

  const AddressSearchField({
    super.key,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.onWaypointSelected,
  });

  @override
  ConsumerState<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends ConsumerState<AddressSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _sugerencias = [];
  bool _cargando = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _onChanged(String value) async {
    if (value.length < 3) {
      _removeOverlay();
      return;
    }
    setState(() => _cargando = true);
    final repo = ref.read(routeRepositoryProvider);
    final result = await repo.autocompleteAddress(value);
    if (!mounted) return;
    setState(() => _cargando = false);
    result.fold(
      (failure) {
        _removeOverlay();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.userMessage),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      },
      (sugerencias) {
        _sugerencias = sugerencias;
        _showOverlay();
      },
    );
  }

  Future<void> _onSugerenciaSelected(String direccion) async {
    _controller.text = direccion;
    _removeOverlay();
    _focusNode.unfocus();
    setState(() => _cargando = true);
    final repo = ref.read(routeRepositoryProvider);
    final result = await repo.geocodeAddress(direccion);
    if (!mounted) return;
    setState(() => _cargando = false);
    result.fold(
      (failure) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron obtener coordenadas: ${failure.userMessage}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
      (waypoint) => widget.onWaypointSelected(waypoint),
    );
  }

  void _showOverlay() {
    _removeOverlay();
    if (_sugerencias.isEmpty) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: offset.dy + size.height + 4,
        left: offset.dx,
        width: size.width,
        child: _SugerenciasDropdown(
          sugerencias: _sugerencias,
          onSelected: _onSugerenciaSelected,
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(widget.icon, color: widget.iconColor, size: 18),
        suffixIcon: _cargando
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _controller.clear();
                      _removeOverlay();
                    },
                  )
                : null,
      ),
    );
  }
}

class _SugerenciasDropdown extends StatelessWidget {
  final List<String> sugerencias;
  final ValueChanged<String> onSelected;

  const _SugerenciasDropdown({
    required this.sugerencias,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.superficieCard,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
          border: Border.all(color: AppTheme.bordeInactivo),
          boxShadow: [
            BoxShadow(
              color: AppTheme.verdeGlow,
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sugerencias.asMap().entries.map((e) {
              final isLast = e.key == sugerencias.length - 1;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => onSelected(e.value),
                    hoverColor: AppTheme.verdeTenue,
                    splashColor: AppTheme.verdePrimario.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMd, vertical: 12),
                      child: Row(
                        children: [
                          const Text('>', style: TextStyle(
                            fontFamily: 'Courier New',
                            color: AppTheme.verdePrimario,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          )),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                fontFamily: 'Courier New',
                                fontSize: 13,
                                color: AppTheme.textoPrimario,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1,
                        color: AppTheme.bordeInactivo,
                        indent: AppTheme.spacingMd),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../routes/domain/entities/route.dart';
import '../../../routes/domain/repositories/i_route_repository.dart';

part 'address_search_field.g.dart';

/// Provider del repositorio de rutas — se registra en InjectionContainer
@riverpod
IRouteRepository routeRepository(Ref ref) {
  throw UnimplementedError('Registra en InjectionContainer');
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
      (_) => _removeOverlay(),
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
    result.fold((_) {}, (waypoint) => widget.onWaypointSelected(waypoint));
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
      elevation: 8,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: sugerencias
              .map((s) => InkWell(
                    onTap: () => onSelected(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingMd,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 16, color: AppTheme.grisMedium),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Text(
                              s,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

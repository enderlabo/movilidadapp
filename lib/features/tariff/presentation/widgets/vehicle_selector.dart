import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection/injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/entities/vehicle_recommendation.dart';
import '../../../vehicles/domain/repositories/i_vehicle_repository.dart';
import '../viewmodels/tariff_viewmodel.dart';

part 'vehicle_selector.g.dart';

@riverpod
IVehicleRepository vehicleRepository(Ref ref) {
  return sl<IVehicleRepository>();
}

@riverpod
Future<List<Vehicle>> vehiculos(Ref ref) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  final result = await repo.getVehiculos();
  final list = result.getOrElse(() => []);
  // DEBUG: ver exactamente qué llega de Firebase
  for (final v in list) {
    debugPrint('[Vehicle] id="${v.id}" nombre="${v.nombre}" placa="${v.placa}" categoria=${v.categoria.name}');
  }
  return list;
}

class VehicleSelector extends ConsumerWidget {
  final ValueChanged<Vehicle> onSelected;

  const VehicleSelector({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiculosAsync = ref.watch(vehiculosProvider);
    final selectedVehicle = ref.watch(
      tariffInputProvider.select((input) => input.vehiculo),
    );
    final recomendacion = ref.watch(
      tariffInputProvider.select((input) => input.recomendacion),
    );
    final seleccionManual = ref.watch(
      tariffInputProvider.select((input) => input.seleccionManual),
    );
    final inputNotifier = ref.read(tariffInputProvider.notifier);

    return vehiculosAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        'Error cargando vehículos: $e',
        style: TextStyle(color: AppTheme.error, fontSize: 13),
      ),
      data: (vehiculos) {
        if (vehiculos.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.glassBorder),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
              color: AppTheme.glassBackground,
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    color: AppTheme.grisMedium, size: 18),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Sin vehículos — agregar en Firebase',
                  style: TextStyle(
                      color: context.c.textoSecundario, fontSize: 13),
                ),
              ],
            ),
          );
        }

        // Asegura que el value seleccionado existe en la lista actual
        final currentValue = vehiculos
            .cast<Vehicle?>()
            .firstWhere((v) => v?.id == selectedVehicle?.id,
                orElse: () => null);

        final recVehicle =
            _vehiculoPorRecomendacion(vehiculos: vehiculos, recomendacion: recomendacion);

        if (currentValue == null) {
          // Primera carga: selecciona el vehículo recomendado si existe,
          // si no el primer pequeño (Forland).
          // Fallback: busca el Forland (BSL) como vehículo predeterminado.
          final defaultVehicle = (!seleccionManual && recVehicle != null)
              ? recVehicle
              : vehiculos.firstWhere(
                  (v) => '${v.nombre} ${v.placa}'.toUpperCase().contains('BSL'),
                  orElse: () => vehiculos.first,
                );
          Future.microtask(() => inputNotifier.autoSelectVehiculo(defaultVehicle));
        } else if (!seleccionManual &&
            recVehicle != null &&
            selectedVehicle?.id != recVehicle.id) {
          // La recomendación cambió (nuevo destino / nuevo peso / nueva ruta)
          // y el usuario NO eligió manualmente → auto-cambiar.
          Future.microtask(() => inputNotifier.autoSelectVehiculo(recVehicle));
        }

        // La clave fuerza reconstrucción del DropdownButtonFormField cuando
        // cambia el vehículo (initialValue solo aplica en initState).
        return DropdownButtonFormField<Vehicle>(
          key: ValueKey(currentValue?.id ?? 'none'),
          initialValue: currentValue,
          decoration: InputDecoration(
            hintText: 'Seleccionar vehículo',
            prefixIcon: Icon(
              currentValue != null
                  ? Icons.local_shipping
                  : Icons.local_shipping_outlined,
              color: currentValue != null
                  ? AppTheme.azulPrimario
                  : AppTheme.grisMedium,
              size: 18,
            ),
          ),
          items: vehiculos
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: _VehicleDropdownItem(vehicle: v),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onSelected(v);
          },
          isExpanded: true,
        );
      },
    );
  }

  Vehicle? _vehiculoPorRecomendacion({
    required List<Vehicle> vehiculos,
    required VehicleRecommendation? recomendacion,
  }) {
    if (recomendacion == null) return null;
    // Firebase guarda placa="" y el número está dentro de nombre ("Placa: CCK-886").
    // Busca la placa recomendada dentro del nombre normalizado del vehículo.
    final placaBuscada = _norm(recomendacion.placaRecomendada);
    try {
      return vehiculos.firstWhere(
        (v) => _norm(v.nombre).contains(placaBuscada) ||
               _norm(v.placa) == placaBuscada,
      );
    } catch (_) {
      return null;
    }
  }

  static String _norm(String? s) =>
      (s ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

class _VehicleDropdownItem extends StatelessWidget {
  final Vehicle vehicle;

  const _VehicleDropdownItem({required this.vehicle});

  static bool _esGnv(Vehicle v) {
    // Firebase almacena la placa dentro de nombre ("Placa: CCK-886").
    // CCK = Dongfeng GNV, BSL = Forland Gasolina.
    final texto = '${v.nombre} ${v.placa}'.toUpperCase();
    return texto.contains('CCK');
  }

  @override
  Widget build(BuildContext context) {
    final esGnv = _esGnv(vehicle);
    final fuelLabel = esGnv ? 'GNV' : 'GASOLINA';
    final fuelColor =
        esGnv ? const Color(0xFF4CAF50) : const Color(0xFFFF8C42);

    return Row(
      children: [
        Expanded(
          child: Text(
            vehicle.nombre,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Courier New',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: fuelColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: fuelColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            fuelLabel,
            style: TextStyle(
              color: fuelColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'Courier New',
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}


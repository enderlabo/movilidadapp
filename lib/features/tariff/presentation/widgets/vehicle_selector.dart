import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection/injection_container.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/repositories/i_vehicle_repository.dart';
import '../viewmodels/tariff_viewmodel.dart';

part 'vehicle_selector.g.dart';

@riverpod
IVehicleRepository vehicleRepository(Ref ref) {
  return sl<IVehicleRepository>();
}

@riverpod
Stream<List<Vehicle>> vehiculos(Ref ref) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.watchVehiculos().map((either) => either.getOrElse(() => []));
}

class VehicleSelector extends ConsumerWidget {
  final ValueChanged<Vehicle> onSelected;

  const VehicleSelector({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiculosAsync = ref.watch(vehiculosProvider);
    final selectedVehicle = ref.watch(
      tariffInputNotifierProvider.select((input) => input.vehiculo),
    );

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
                      color: AppTheme.textoSecundario, fontSize: 13),
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

        // Auto-selecciona el primer camión pequeño al cargar
        if (currentValue == null) {
          final defaultVehicle = vehiculos.firstWhere(
            (v) => v.categoria == CategoriaVehiculo.pequeno,
            orElse: () => vehiculos.first,
          );
          Future.microtask(() => onSelected(defaultVehicle));
        }

        return DropdownButtonFormField<Vehicle>(
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
                    child: Text(
                      v.nombre,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Courier New',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
}

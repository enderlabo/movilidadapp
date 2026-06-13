import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/domain/repositories/i_vehicle_repository.dart';

part 'vehicle_selector.g.dart';

@riverpod
IVehicleRepository vehicleRepository(Ref ref) {
  throw UnimplementedError('Registra en InjectionContainer');
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

    return vehiculosAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        'Error cargando vehículos',
        style: TextStyle(color: AppTheme.error, fontSize: 13),
      ),
      data: (vehiculos) => DropdownButtonFormField<Vehicle>(
        decoration: InputDecoration(
          hintText: 'Seleccionar vehículo',
          prefixIcon: Icon(
            Icons.local_shipping_outlined,
            color: AppTheme.azulPrimario,
            size: 18,
          ),
        ),
        items: vehiculos
            .map((v) => DropdownMenuItem(
                  value: v,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        v.nombre,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${v.placa} · ${v.tipo.displayName} · '
                        '${v.rendimientoKmPorGalonCargado} km/gal cargado',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textoSecundario),
                      ),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onSelected(v);
        },
        isExpanded: true,
      ),
    );
  }
}

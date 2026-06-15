import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
import '../../../../injection/injection_container.dart';
import '../../domain/entities/tarifa_zona.dart';
import '../../domain/repositories/i_tarifa_zona_repository.dart';

part 'tarifas_viewmodel.g.dart';

@riverpod
ITarifaZonaRepository tarifaZonaRepo(Ref ref) => sl<ITarifaZonaRepository>();

@riverpod
Stream<List<TarifaZona>> tarifasStream(Ref ref) {
  return ref
      .watch(tarifaZonaRepoProvider)
      .watchTarifas()
      .map((e) => e.getOrElse(() => []));
}

@riverpod
class TarifasNotifier extends _$TarifasNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> guardar(TarifaZona tarifa) async {
    state = const AsyncLoading();
    final result = await ref.read(tarifaZonaRepoProvider).saveTarifa(tarifa);
    state = result.fold(
      (f) => AsyncError(f.userMessage, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> eliminar(String id) async {
    state = const AsyncLoading();
    final result = await ref.read(tarifaZonaRepoProvider).deleteTarifa(id);
    state = result.fold(
      (f) => AsyncError(f.userMessage, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}

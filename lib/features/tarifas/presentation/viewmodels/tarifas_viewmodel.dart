import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/async_command.dart';
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

  Future<void> guardar(TarifaZona tarifa) => runEitherCommand(
        () => ref.read(tarifaZonaRepoProvider).saveTarifa(tarifa),
        setState: (s) => state = s,
      );

  Future<void> eliminar(String id) => runEitherCommand(
        () => ref.read(tarifaZonaRepoProvider).deleteTarifa(id),
        setState: (s) => state = s,
      );
}

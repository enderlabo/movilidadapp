import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/async_command.dart';
import '../../../../injection/injection_container.dart';
import '../../domain/entities/zona_tarifaria.dart';
import '../../domain/repositories/i_zona_tarifaria_repository.dart';

part 'zonas_viewmodel.g.dart';

@riverpod
IZonaTarifariaRepository zonasTarifariaRepo(Ref ref) =>
    sl<IZonaTarifariaRepository>();

@riverpod
Stream<List<ZonaTarifaria>> zonasStream(Ref ref) {
  return ref
      .watch(zonasTarifariaRepoProvider)
      .watchZonas()
      .map((e) => e.getOrElse(() => []));
}

@riverpod
class ZonasNotifier extends _$ZonasNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> guardar(ZonaTarifaria zona) => runEitherCommand(
        () => ref.read(zonasTarifariaRepoProvider).saveZona(zona),
        setState: (s) => state = s,
      );

  Future<void> eliminar(String id) => runEitherCommand(
        () => ref.read(zonasTarifariaRepoProvider).deleteZona(id),
        setState: (s) => state = s,
      );

  Future<void> seedDefault() => runEitherCommand(
        () => ref.read(zonasTarifariaRepoProvider).seedZonasDefault(),
        setState: (s) => state = s,
      );
}

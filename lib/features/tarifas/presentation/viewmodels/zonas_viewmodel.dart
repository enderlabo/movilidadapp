import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/error/failures.dart';
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

  Future<void> guardar(ZonaTarifaria zona) async {
    state = const AsyncLoading();
    final result =
        await ref.read(zonasTarifariaRepoProvider).saveZona(zona);
    state = result.fold(
      (f) => AsyncError(f.userMessage, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> eliminar(String id) async {
    state = const AsyncLoading();
    final result =
        await ref.read(zonasTarifariaRepoProvider).deleteZona(id);
    state = result.fold(
      (f) => AsyncError(f.userMessage, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  Future<void> seedDefault() async {
    state = const AsyncLoading();
    final result =
        await ref.read(zonasTarifariaRepoProvider).seedZonasDefault();
    state = result.fold(
      (f) => AsyncError(f.userMessage, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}

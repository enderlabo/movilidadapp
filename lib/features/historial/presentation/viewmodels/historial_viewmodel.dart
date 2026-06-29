import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../injection/injection_container.dart';
import '../../../tarifas/domain/entities/cotizacion_tarifario.dart';
import '../../domain/repositories/i_historial_repository.dart';

part 'historial_viewmodel.g.dart';

@riverpod
IHistorialRepository historialRepository(Ref ref) => sl<IHistorialRepository>();

@riverpod
Stream<List<CotizacionTarifario>> historialStream(Ref ref) {
  return ref
      .watch(historialRepositoryProvider)
      .watchHistorial()
      .map((e) => e.getOrElse(() => []));
}

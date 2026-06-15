import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../injection/injection_container.dart';
import '../../../../core/network/local_cache.dart';
import '../../domain/entities/tarifa_config.dart';

part 'tarifa_config_viewmodel.g.dart';

@Riverpod(keepAlive: true)
class TarifaConfigNotifier extends _$TarifaConfigNotifier {
  static const _key = 'tarifa_config';

  @override
  Future<TarifaConfig> build() async {
    final cache = sl<LocalCache>();
    final json = await cache.getJson(_key);
    if (json == null) return TarifaConfig.defaults;
    return TarifaConfig.fromJson(json);
  }

  Future<void> guardar(TarifaConfig config) async {
    final cache = sl<LocalCache>();
    await cache.setJson(_key, config.toJson());
    state = AsyncData(config);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../injection/injection_container.dart';
import '../../../../core/network/local_cache.dart';
import '../../domain/entities/tarifa_config.dart';

part 'tarifa_config_viewmodel.g.dart';

/// Manual provider (no codegen) for the local cache.
final localCacheProvider = Provider<LocalCache>((ref) => sl<LocalCache>());

@Riverpod(keepAlive: true)
class TarifaConfigNotifier extends _$TarifaConfigNotifier {
  static const _key = 'tarifa_config';

  LocalCache get _cache => ref.read(localCacheProvider);

  @override
  Future<TarifaConfig> build() async {
    final json = await _cache.getJson(_key);
    if (json == null) return TarifaConfig.defaults;
    return TarifaConfig.fromJson(json);
  }

  Future<void> guardar(TarifaConfig config) async {
    await _cache.setJson(_key, config.toJson());
    state = AsyncData(config);
  }
}

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../error/failures.dart';

/// DRY helper for the CRUD ViewModel commands.
///
/// Centralizes the repeated `AsyncLoading → fold(AsyncError, AsyncData)` pattern
/// shared by `TarifasNotifier`, `ZonasNotifier`, etc. The notifier only provides
/// how to write its (protected) `state` via [setState].
Future<void> runEitherCommand<T>(
  Future<Either<Failure, T>> Function() action, {
  required void Function(AsyncValue<void>) setState,
}) async {
  setState(const AsyncLoading());
  final result = await action();
  setState(result.fold(
    (f) => AsyncError(f.userMessage, StackTrace.current),
    (_) => const AsyncData(null),
  ));
}

import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// DRY helpers for the data layer.
///
/// Every repository implementation shares the same pattern: run I/O and
/// translate any exception into a [Failure] inside an [Either]. Instead of
/// repeating `try { … } catch (e) { return Left(…) }` in every method, it is
/// centralized here.
///
/// Exceptions map to [Failure.database] by default; pass [onError] to customize
/// (e.g. network sources → [Failure.network]).

/// Runs an async operation and captures its exceptions as [Left].
Future<Either<Failure, T>> guardFuture<T>(
  Future<T> Function() body, {
  Failure Function(Object error)? onError,
}) async {
  try {
    return Right(await body());
  } catch (e) {
    return Left(onError?.call(e) ?? Failure.database(message: e.toString()));
  }
}

/// Maps each event of [source] through [transform], capturing any exception
/// from the transform as [Left]. Intended for Firestore `snapshots()` where
/// deserialization may throw.
Stream<Either<Failure, R>> guardStream<S, R>(
  Stream<S> source,
  R Function(S event) transform, {
  Failure Function(Object error)? onError,
}) {
  return source.map<Either<Failure, R>>((event) {
    try {
      return Right(transform(event));
    } catch (e) {
      return Left(onError?.call(e) ?? Failure.database(message: e.toString()));
    }
  });
}

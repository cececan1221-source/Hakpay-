/// Basit Result tipi — Ok / Err.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T? get valueOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  String? get errorOrNull => switch (this) {
        Ok() => null,
        Err(:final message) => message,
      };

  R when<R>({
    required R Function(T value) ok,
    required R Function(String message) err,
  }) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final message) => err(message),
      };
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final String message;
  const Err(this.message);
}

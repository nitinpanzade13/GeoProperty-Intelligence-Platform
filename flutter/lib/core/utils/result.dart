abstract class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(String message, [Exception? exception]) = Failure<T>;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;
  const Failure(this.message, [this.exception]);
}

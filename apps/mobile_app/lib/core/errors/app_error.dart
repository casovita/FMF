sealed class AppError implements Exception {
  const AppError(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class PersistenceError extends AppError {
  const PersistenceError(super.message);
}

final class NetworkError extends AppError {
  const NetworkError(super.message);
}

final class UnknownError extends AppError {
  const UnknownError(super.message);
}

import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable implements Exception {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

final class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}

// lib/core/errors/failures.dart
//
// Discriminated union of application-level failures.
// Using sealed classes instead of plain exceptions gives the compiler exhaustive
// switch coverage — callers are forced to handle every failure kind.

import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// A network request failed — timeout, 4xx, 5xx, etc.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {this.statusCode});
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// The API key is missing, malformed, or unauthorised (HTTP 401/403).
final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// A required local executable (node, ffmpeg, yt-dlp) is not in PATH.
final class MissingToolFailure extends Failure {
  const MissingToolFailure(this.tool)
    : super('Required tool "$tool" not found in PATH.');
  final String tool;

  @override
  List<Object?> get props => [message, tool];
}

/// A subprocess exited with a non-zero exit code.
final class ProcessFailure extends Failure {
  const ProcessFailure(
    super.message, {
    this.exitCode,
    this.stderr,
    this.retryable = true,
    this.errorCategory,
  });
  final int? exitCode;
  final String? stderr;
  final bool retryable;
  final String? errorCategory;

  @override
  List<Object?> get props => [
    message,
    exitCode,
    stderr,
    retryable,
    errorCategory,
  ];
}

/// A file or directory operation failed (read, write, not found).
final class FileSystemFailure extends Failure {
  const FileSystemFailure(super.message);
}

/// JSON decode / schema validation failed.
final class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

/// The Isar database operation failed.
final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

/// A user-facing validation error (e.g., empty prompt, invalid URL).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// An unexpected error that doesn't fit another category.
final class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

// lib/core/errors/error_handler.dart
//
// Central error presentation layer. Never let raw exceptions bubble to the UI.
// All error display goes through here so styling and UX is consistent.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veox_flutter/core/errors/failures.dart';
import 'package:veox_flutter/core/utils/logger.dart';

/// Maps a [Failure] to a user-friendly string.
String failureToMessage(Failure failure) {
  return switch (failure) {
    AuthFailure() =>
      'API key missing or invalid. Go to Settings to add your key.',
    MissingToolFailure(:final tool) =>
      '"$tool" is not installed. Run: brew install $tool',
    NetworkFailure(:final statusCode) when statusCode == 429 =>
      'Rate limit hit. Wait a moment and try again.',
    NetworkFailure(:final statusCode) when statusCode != null && statusCode >= 500 =>
      'The API server is having issues. Try again shortly.',
    NetworkFailure() => failure.message,
    ProcessFailure() => 'Process error: ${failure.message}',
    FileSystemFailure() => 'File error: ${failure.message}',
    ParseFailure() => 'Could not parse API response. Please report this.',
    DatabaseFailure() => 'Database error: ${failure.message}',
    ValidationFailure() => failure.message,
    UnknownFailure() => 'An unexpected error occurred.',
  };
}

/// Shows a brief [SnackBar] for recoverable errors.
void showErrorSnackbar(BuildContext context, Failure failure) {
  if (!context.mounted) return;

  final msg = failureToMessage(failure);
  AppLogger.warn('UI Error: $msg', tag: 'ErrorHandler');

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
}

/// Shows a blocking [AlertDialog] for critical errors.
Future<void> showErrorDialog(BuildContext context, Failure failure,
    {String? title}) async {
  if (!context.mounted) return;

  final msg = failureToMessage(failure);
  AppLogger.error('Critical UI Error: $msg', tag: 'ErrorHandler');

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title ?? 'Error', style: const TextStyle(color: Colors.red)),
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// [VeoxProviderObserver] logs all Riverpod state transitions.
/// Add to [ProviderScope] in main.dart.
class VeoxProviderObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    AppLogger.debug('Provider added: ${provider.name ?? provider.runtimeType}',
        tag: 'Riverpod');
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    AppLogger.debug(
        'Provider updated: ${provider.name ?? provider.runtimeType}',
        tag: 'Riverpod');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.error(
      'Provider failed: ${provider.name ?? provider.runtimeType}',
      tag: 'Riverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

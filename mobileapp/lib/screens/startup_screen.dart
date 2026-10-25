import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../theme/tokens.dart';

/// Shown while the app connects to the server. On Render's free tier a sleeping
/// server takes about a minute to wake up, so we explain the wait.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  static const _expectedSeconds = 60;

  final Stopwatch _clock = Stopwatch()..start();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final seconds = _clock.elapsed.inSeconds;
    final error = session.startupError;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: error != null
                  ? _ErrorView(
                      message: error,
                      onRetry: () {
                        _clock.reset();
                        session.retryStartup();
                      },
                    )
                  : ValueListenableBuilder<bool>(
                      valueListenable: session.api.serverWaking,
                      builder: (context, waking, _) =>
                          _WakingView(waking: waking, seconds: seconds),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WakingView extends StatelessWidget {
  const _WakingView({required this.waking, required this.seconds});

  final bool waking;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = waking ? 'Waking up the server…' : 'Connecting…';
    final body = !waking
        ? 'Getting things ready.'
        : seconds > 90
            ? 'Still working on it. Thanks for your patience.'
            : 'Forkcast runs on a free server that naps when nobody is using '
                'it. Waking it up usually takes about a minute.';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.restaurant_menu, size: 56, color: context.fc.accent),
        const SizedBox(height: 8),
        Text(
          'Forkcast',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: context.fc.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(body, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (waking) ...[
          LinearProgressIndicator(
            value: (seconds / _StartupScreenState._expectedSeconds)
                .clamp(0.0, 0.95),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Text('${seconds}s', style: theme.textTheme.bodySmall),
        ] else
          const CircularProgressIndicator(),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off, size: 56, color: context.fc.accent),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}

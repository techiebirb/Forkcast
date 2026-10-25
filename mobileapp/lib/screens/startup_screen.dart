import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../theme/fc_tokens.dart';
import '../widgets/fc_button.dart';
import '../widgets/fc_icons.dart';
import '../widgets/fc_logo.dart';
import '../widgets/fc_surfaces.dart';

/// Shown while the app connects to the server. On Render's free tier a sleeping
/// server takes about a minute to wake up, so we explain the wait.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  static const _expectedSeconds = 60;
  static const _longWaitSeconds = 90;

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
      backgroundColor: context.fc.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(FcSpace.s8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Brand(),
                  const SizedBox(height: 40),
                  if (error != null)
                    _ErrorView(
                      onRetry: () {
                        _clock.reset();
                        session.retryStartup();
                      },
                    )
                  else
                    ValueListenableBuilder<bool>(
                      valueListenable: session.api.serverWaking,
                      builder: (context, waking, _) => waking
                          ? _WakingView(
                              seconds: seconds,
                              progress: (seconds / _expectedSeconds)
                                  .clamp(0.0, 0.95),
                              longWait: seconds > _longWaitSeconds,
                            )
                          : const _ConnectingView(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FcLogoMark(size: 56),
        const SizedBox(height: FcSpace.s3),
        Text(
          'Forkcast',
          style: FcText.display.copyWith(color: context.fc.textPrimary),
        ),
      ],
    );
  }
}

class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Semantics(
      liveRegion: true,
      container: true,
      label: 'Connecting. Getting things ready.',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FcSpinner(size: 24, color: c.accent),
            const SizedBox(height: FcSpace.s3),
            Text(
              'Connecting…',
              textAlign: TextAlign.center,
              style: FcText.heading.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: FcSpace.s3),
            Text(
              'Getting things ready.',
              textAlign: TextAlign.center,
              style: FcText.bodySm.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _WakingView extends StatelessWidget {
  const _WakingView({
    required this.seconds,
    required this.progress,
    required this.longWait,
  });

  final int seconds;
  final double progress;
  final bool longWait;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final body = longWait
        ? 'Still working on it. Thanks for your patience.'
        : 'Forkcast runs on a free server that naps when nobody is using it. '
            'Waking it up usually takes about a minute.';
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Waking up the server…',
            textAlign: TextAlign.center,
            style: FcText.heading.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: FcSpace.s3),
          Text(
            body,
            textAlign: TextAlign.center,
            style: FcText.bodySm.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: FcSpace.s6),
          FcProgressBar(value: progress, semanticLabel: 'Waking up the server'),
          const SizedBox(height: FcSpace.s3),
          Semantics(
            label: '$seconds seconds',
            excludeSemantics: true,
            child: Text(
              '${seconds}s',
              style: FcText.tabular(FcText.caption).copyWith(
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.dangerSoft,
            ),
            child: Center(
              child: FcIcon(FcIcons.cloudOff, size: 24, color: c.danger),
            ),
          ),
          const SizedBox(height: FcSpace.s3),
          Text(
            "Couldn't reach Forkcast.",
            textAlign: TextAlign.center,
            style: FcText.heading.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: FcSpace.s3),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: FcText.bodySm.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: FcSpace.s6),
          FcButton(
            label: 'Try again',
            large: true,
            block: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/tokens.dart';

/// Small ring spinner in the current text color.
class FcSpinner extends StatelessWidget {
  const FcSpinner({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        value: still ? 0.75 : null,
        color: color ?? DefaultTextStyle.of(context).style.color,
      ),
    );
  }
}

/// Empty and error states: round icon, title, body, optional action.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.title,
    required this.body,
    this.error = false,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final bool error;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FcSpace.s6,
          vertical: FcSpace.s8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: error ? c.dangerSoft : c.surfaceSunken,
              ),
              child: Icon(
                icon ??
                    (error
                        ? PhosphorIconsRegular.wifiSlash
                        : PhosphorIconsRegular.bowlFood),
                size: 28,
                color: error ? c.danger : c.textSecondary,
              ),
            ),
            const SizedBox(height: FcSpace.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: FcSpace.s2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 288),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium!.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: FcSpace.s5),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pulsing placeholder rows shaped like restaurant cards.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.rows = 3, this.label = 'Loading'});

  final int rows;
  final String label;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    Widget line(double widthFactor) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: c.surfaceSunken,
              borderRadius: BorderRadius.circular(FcRadius.sm),
            ),
          ),
        );
    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Opacity(
            // 1 → 0.5 → 1, like the web ease-in-out pulse.
            opacity: 0.75 + 0.25 * math.cos(_pulse.value * 2 * math.pi),
            child: child,
          ),
          child: Column(
            children: [
              for (var i = 0; i < widget.rows; i++) ...[
                if (i > 0) const SizedBox(height: FcSpace.s3),
                Container(
                  padding: const EdgeInsets.all(FcSpace.s4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(FcRadius.card),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: c.surfaceSunken,
                          borderRadius: BorderRadius.circular(FcRadius.input),
                        ),
                      ),
                      const SizedBox(width: FcSpace.s3),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            children: [
                              line(0.62),
                              const SizedBox(height: FcSpace.s2),
                              line(0.84),
                              const SizedBox(height: FcSpace.s2),
                              line(0.40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Determinate progress bar (server wake-up).
class FcProgress extends StatelessWidget {
  const FcProgress({super.key, required this.value, this.label});

  /// 0..1
  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Semantics(
      label: label,
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FcRadius.pill),
        child: SizedBox(
          height: 8,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: c.surfaceSunken),
              TweenAnimationBuilder<double>(
                tween: Tween(end: value.clamp(0, 1)),
                duration: FcMotion.of(context, const Duration(seconds: 1)),
                builder: (context, v, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(FcRadius.pill),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum FcStep { done, current, waiting }

/// AI progress steps: done = check, current = spinner, waiting = hollow dot.
class StepsList extends StatelessWidget {
  const StepsList({super.key, required this.steps});

  final List<(String, FcStep)> steps;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, state) in steps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: Center(
                    child: switch (state) {
                      FcStep.done => Icon(PhosphorIconsRegular.check,
                          size: 16, color: c.accent),
                      FcStep.current => FcSpinner(size: 16, color: c.accent),
                      FcStep.waiting => Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: c.borderStrong, width: 2),
                          ),
                        ),
                    },
                  ),
                ),
                const SizedBox(width: FcSpace.s2),
                Expanded(
                  child: Text(
                    label,
                    style: context.text.bodyMedium!.copyWith(
                      color: state == FcStep.waiting
                          ? c.textSecondary
                          : c.textPrimary,
                      fontWeight: state == FcStep.current
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Section heading with an optional count: "Fits you · 2".
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(text, style: context.text.titleMedium),
      );
}

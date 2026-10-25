import 'package:flutter/material.dart';

import '../theme/fc_tokens.dart';
import 'fc_button.dart';
import 'fc_icons.dart';

/// Card on the page background: surface fill and a hairline border, no shadow.
class FcCard extends StatelessWidget {
  const FcCard({
    super.key,
    required this.child,
    this.padding,
    this.clip = false,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Clip children to the rounded corners (for lists with full-width rows).
  final bool clip;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(FcRadius.card),
        border: Border.all(color: borderColor ?? c.border),
      ),
      child: child,
    );
  }
}

/// Segmented control on a sunken pill track. Also used as the tab strip on
/// the Saved screen.
class FcSeg extends StatelessWidget {
  const FcSeg({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.semanticLabel,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(FcSpace.s1),
        decoration: ShapeDecoration(
          color: c.surfaceSunken,
          shape: const StadiumBorder(),
        ),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: FcSpace.s1),
              Expanded(child: _option(context, i)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, int index) {
    final c = context.fc;
    final selected = index == selectedIndex;
    final shape = StadiumBorder(
      side: selected ? BorderSide(color: c.borderStrong) : BorderSide.none,
    );
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: options[index],
      excludeSemantics: true,
      onTap: () => onChanged(index),
      child: Material(
        color: selected ? c.surfaceRaised : Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: () => onChanged(index),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kFcTargetMin),
            child: Center(
              child: Text(
                options[index],
                style: FcText.label.copyWith(
                  color: selected ? c.textPrimary : c.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// In-body top bar: optional back button, title (or wordmark) with an
/// optional location line, and trailing actions. Wrap in a [SafeArea].
class FcAppBar extends StatelessWidget {
  const FcAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleIcon,
    this.onBack,
    this.backLabel = 'Back',
    this.showBack = true,
    this.actions = const [],
  });

  final String? title;

  /// Accessible name of the back button, e.g. "Back to results".
  final String backLabel;

  /// Replaces [title], e.g. the wordmark on Home.
  final Widget? titleWidget;
  final String? subtitle;
  final IconData? subtitleIcon;
  final VoidCallback? onBack;
  final bool showBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FcSpace.s2,
        FcSpace.s3,
        FcSpace.s2,
        FcSpace.s1,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            if (showBack)
              FcButton(
                label: backLabel,
                variant: FcButtonVariant.ghost,
                iconOnly: true,
                icon: FcIcons.caretLeft,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: FcSpace.s2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (titleWidget != null)
                      titleWidget!
                    else if (title != null)
                      Semantics(
                        header: true,
                        child: Text(
                          title!,
                          style: FcText.wordmark.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    if (subtitle != null)
                      Row(
                        children: [
                          if (subtitleIcon != null) ...[
                            FcIcon(
                              subtitleIcon!,
                              size: 16,
                              color: c.textSecondary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              subtitle!,
                              style: FcText.bodySm.copyWith(
                                fontSize: 13,
                                height: 18 / 13,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

enum ListStateKind { loading, empty, error }

/// Loading skeleton, empty state or error panel, always with a next step.
class ListState extends StatelessWidget {
  const ListState({
    super.key,
    required this.kind,
    this.title = '',
    this.body = '',
    this.actionLabel,
    this.onAction,
    this.rows = 3,
    this.icon,
  });

  final ListStateKind kind;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Skeleton rows for [ListStateKind.loading].
  final int rows;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (kind == ListStateKind.loading) {
      return _Skeleton(rows: rows);
    }
    final c = context.fc;
    final isError = kind == ListStateKind.error;
    final glyph =
        icon ?? (isError ? FcIcons.cloudOff : FcIcons.magnifyingGlass);
    return Semantics(
      container: true,
      liveRegion: isError,
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
              margin: const EdgeInsets.only(bottom: FcSpace.s2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isError ? c.dangerSoft : c.surfaceSunken,
              ),
              child: Center(
                child: FcIcon(
                  glyph,
                  size: 24,
                  color: isError ? c.danger : c.textSecondary,
                ),
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: FcText.heading.copyWith(color: c.textPrimary),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: FcSpace.s2),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 288),
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: FcText.bodySm.copyWith(color: c.textSecondary),
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: FcSpace.s4),
              FcButton(
                label: actionLabel!,
                variant: FcButtonVariant.secondary,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatefulWidget {
  const _Skeleton({required this.rows});

  final int rows;

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
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
    Widget line(double factor) => FractionallySizedBox(
          widthFactor: factor,
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: c.surfaceSunken,
              borderRadius: BorderRadius.circular(FcRadius.sm),
            ),
          ),
        );
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.55).animate(_pulse),
        child: Column(
          children: [
            for (var i = 0; i < widget.rows; i++) ...[
              if (i > 0) const SizedBox(height: FcSpace.s3),
              FcCard(
                padding: const EdgeInsets.all(FcSpace.s4),
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
                        padding: const EdgeInsets.only(top: FcSpace.s1),
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
    );
  }
}

/// Determinate progress, used while the server wakes up.
class FcProgressBar extends StatelessWidget {
  const FcProgressBar({super.key, required this.value, this.semanticLabel});

  /// 0 to 1.
  final double value;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      value: '${(clamped * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FcRadius.pill),
        child: Container(
          height: 8,
          width: double.infinity,
          color: c.surfaceSunken,
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, box) => AnimatedContainer(
              duration: reduce ? Duration.zero : const Duration(seconds: 1),
              curve: Curves.linear,
              width: box.maxWidth * clamped,
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(FcRadius.pill),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet body: grab handle, title, optional text, then actions.
class FcSheet extends StatelessWidget {
  const FcSheet({
    super.key,
    required this.title,
    this.body,
    this.actions = const [],
  });

  final String title;
  final String? body;

  /// Usually two [FcButton]s; laid out side by side at equal width.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: title,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(FcRadius.sheet),
          ),
          boxShadow: c.shadowRaised,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: FcSpace.s2),
                  decoration: BoxDecoration(
                    color: c.borderStrong,
                    borderRadius: BorderRadius.circular(FcRadius.pill),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FcSpace.s5,
                  FcSpace.s4,
                  FcSpace.s5,
                  0,
                ),
                child: Text(
                  title,
                  style: FcText.wordmark.copyWith(color: c.textPrimary),
                ),
              ),
              if (body != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FcSpace.s5,
                    FcSpace.s2,
                    FcSpace.s5,
                    0,
                  ),
                  child: Text(
                    body!,
                    style: FcText.body.copyWith(color: c.textSecondary),
                  ),
                ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FcSpace.s4,
                    FcSpace.s4,
                    FcSpace.s4,
                    FcSpace.s4,
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: FcSpace.s2),
                        Expanded(child: actions[i]),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [builder] in a Forkcast bottom sheet (scrim, 24px top corners).
Future<T?> showFcSheet<T>(BuildContext context, WidgetBuilder builder) {
  final c = context.fc;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: c.scrim,
    elevation: 0,
    builder: builder,
  );
}

/// Inline error banner for a form: warning icon, bold [message], optional
/// plain [detail]. Announced to screen readers as it appears.
class FcAlert extends StatelessWidget {
  const FcAlert({super.key, required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(FcSpace.s3),
        decoration: BoxDecoration(
          color: c.dangerSoft,
          borderRadius: BorderRadius.circular(FcRadius.input),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FcIcon(FcIcons.warning, size: 20, color: c.danger),
            const SizedBox(width: FcSpace.s2),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: message,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (detail != null) TextSpan(text: ' $detail'),
                  ],
                ),
                style: FcText.bodySm.copyWith(color: c.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

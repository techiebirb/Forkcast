import 'package:flutter/material.dart';

import '../theme/fc_tokens.dart';
import 'fc_icons.dart';

enum FcButtonVariant { primary, secondary, ghost, destructive }

/// Small progress spinner in the current text color. Holds still under
/// "reduce motion" (shows a three-quarter ring instead of spinning).
class FcSpinner extends StatelessWidget {
  const FcSpinner({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SizedBox(
      width: size,
      height: size,
      child: ExcludeSemantics(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: reduce ? 0.75 : null,
          color: color ?? DefaultTextStyle.of(context).style.color,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

/// Pill button from the design system: primary, secondary, ghost or
/// destructive; medium (44) or large (52); optionally block width or
/// icon-only (then [label] is the accessible name).
class FcButton extends StatefulWidget {
  const FcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = FcButtonVariant.primary,
    this.large = false,
    this.block = false,
    this.icon,
    this.iconOnly = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final FcButtonVariant variant;
  final bool large;
  final bool block;
  final IconData? icon;
  final bool iconOnly;
  final bool loading;

  @override
  State<FcButton> createState() => _FcButtonState();
}

class _FcButtonState extends State<FcButton> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;
  bool get _disabled => widget.onPressed == null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final v = widget.variant;

    Color bg;
    Color fg;
    BorderSide side = BorderSide.none;
    if (_disabled) {
      bg = v == FcButtonVariant.ghost ? Colors.transparent : c.surfaceSunken;
      fg = c.textDisabled;
    } else {
      switch (v) {
        case FcButtonVariant.primary:
          bg = _pressed && _enabled ? c.accentPressed : c.accent;
          fg = c.onAccent;
        case FcButtonVariant.secondary:
          bg = _pressed && _enabled ? c.surfaceSunken : c.surfaceRaised;
          fg = c.textPrimary;
          side = BorderSide(color: c.borderStrong);
        case FcButtonVariant.ghost:
          bg = _pressed && _enabled ? c.accentSoft : Colors.transparent;
          fg = widget.iconOnly ? c.textSecondary : c.accent;
        case FcButtonVariant.destructive:
          bg = _pressed && _enabled ? c.dangerPressed : c.danger;
          fg = c.onDanger;
      }
    }

    final textStyle = (widget.large
            ? FcText.body.copyWith(fontWeight: FontWeight.w600)
            : FcText.label)
        .copyWith(color: fg);
    final minHeight = widget.large ? 52.0 : kFcTargetMin;

    final Widget content;
    if (widget.iconOnly) {
      content = widget.loading
          ? FcSpinner(color: fg)
          : FcIcon(widget.icon ?? FcIcons.x, size: 20, color: fg);
    } else {
      content = Row(
        mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.loading) ...[
            FcSpinner(color: fg),
            const SizedBox(width: FcSpace.s2),
          ] else if (widget.icon != null) ...[
            FcIcon(widget.icon!, size: 20, color: fg),
            const SizedBox(width: FcSpace.s2),
          ],
          Flexible(
            child: Text(
              widget.label,
              style: textStyle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final shape = StadiumBorder(side: side);
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.iconOnly ? widget.label : null,
      excludeSemantics: widget.iconOnly,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minHeight,
          minWidth: widget.iconOnly ? kFcTargetMin : 0,
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: ShapeDecoration(
            shape: StadiumBorder(
              side: _focused
                  ? BorderSide(color: c.focus, width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Material(
            color: bg,
            shape: shape,
            child: InkWell(
              customBorder: shape,
              onTap: _enabled ? widget.onPressed : null,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              onFocusChange: (value) => setState(() => _focused = value),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Padding(
                padding: widget.iconOnly
                    ? EdgeInsets.zero
                    : EdgeInsets.symmetric(
                        horizontal: widget.large ? 24 : 20,
                        vertical: FcSpace.s2,
                      ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: minHeight - (widget.iconOnly ? 0 : 16),
                  ),
                  child: Center(
                    widthFactor: widget.block ? null : 1,
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

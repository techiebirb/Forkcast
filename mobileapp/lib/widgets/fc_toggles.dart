import 'package:flutter/material.dart';

import '../theme/fc_tokens.dart';
import 'fc_icons.dart';

/// 44px icon button that flips between an outline and a filled icon. The
/// pressed state is shown by the filled glyph and the accent color, and is
/// announced as "toggled" with a label that says what a tap will do.
class _IconToggle extends StatelessWidget {
  const _IconToggle({
    required this.pressed,
    required this.onPressed,
    required this.outline,
    required this.filled,
    required this.labelOn,
    required this.labelOff,
  });

  final bool pressed;
  final VoidCallback? onPressed;
  final IconData outline;
  final IconData filled;
  final String labelOn;
  final String labelOff;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Semantics(
      button: true,
      toggled: pressed,
      enabled: onPressed != null,
      label: pressed ? labelOn : labelOff,
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox(
        width: kFcTargetMin,
        height: kFcTargetMin,
        child: InkResponse(
          onTap: onPressed,
          radius: 22,
          highlightShape: BoxShape.circle,
          child: Center(
            child: FcIcon(
              pressed ? filled : outline,
              size: 20,
              color: pressed ? c.accent : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bookmark: save or remove a restaurant or a dish. Pass [name] so the spoken
/// label says what a tap will do ("Remove Saffron & Salt from Saved").
class BookmarkToggle extends StatelessWidget {
  const BookmarkToggle({
    super.key,
    required this.pressed,
    required this.onPressed,
    this.name,
  });

  final bool pressed;
  final VoidCallback? onPressed;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final what = name == null ? '' : ' $name';
    return _IconToggle(
      pressed: pressed,
      onPressed: onPressed,
      outline: FcIcons.bookmark,
      filled: FcIcons.bookmarkFilled,
      labelOn: 'Remove$what from Saved',
      labelOff: 'Save$what',
    );
  }
}

import 'package:flutter/widgets.dart';

import '../theme/fc_tokens.dart';

/// Icon names used by the design, as Phosphor glyphs. The fonts are bundled
/// under assets/fonts; codepoints come from the Phosphor Regular and Fill sets
/// (they are the same in both).
abstract final class FcIcons {
  static const caretLeft = IconData(0xe138, fontFamily: 'Phosphor');
  static const caretRight = IconData(0xe13a, fontFamily: 'Phosphor');
  static const magnifyingGlass = IconData(0xe30c, fontFamily: 'Phosphor');
  static const storefront = IconData(0xe470, fontFamily: 'Phosphor');
  static const bowlFood = IconData(0xeaa4, fontFamily: 'Phosphor');
  static const forkKnife = IconData(0xe262, fontFamily: 'Phosphor');
  static const walk = IconData(0xe73a, fontFamily: 'Phosphor');
  static const mapPin = IconData(0xe316, fontFamily: 'Phosphor');
  static const user = IconData(0xe4c2, fontFamily: 'Phosphor');
  static const x = IconData(0xe4f6, fontFamily: 'Phosphor');
  static const check = IconData(0xe182, fontFamily: 'Phosphor');
  static const checkCircle = IconData(0xe184, fontFamily: 'Phosphor');
  static const xCircle = IconData(0xe4f8, fontFamily: 'Phosphor');
  static const warning = IconData(0xe4e0, fontFamily: 'Phosphor');
  static const info = IconData(0xe2ce, fontFamily: 'Phosphor');
  static const swap = IconData(0xe83c, fontFamily: 'Phosphor');
  static const sealCheck = IconData(0xe606, fontFamily: 'Phosphor');
  static const trash = IconData(0xe4a6, fontFamily: 'Phosphor');
  static const cloudOff = IconData(0xe1b6, fontFamily: 'Phosphor');

  // Allergen glyphs.
  static const acorn = IconData(0xeb9a, fontFamily: 'Phosphor');
  static const shrimp = IconData(0xeab4, fontFamily: 'Phosphor');
  static const fish = IconData(0xe728, fontFamily: 'Phosphor');
  static const egg = IconData(0xe812, fontFamily: 'Phosphor');
  static const cheese = IconData(0xe9fe, fontFamily: 'Phosphor');
  static const bread = IconData(0xe81c, fontFamily: 'Phosphor');

  // Toggles come in an outline and a filled form.
  static const star = IconData(0xe46a, fontFamily: 'Phosphor');
  static const starFilled = IconData(0xe46a, fontFamily: 'PhosphorFill');
  static const bookmark = IconData(0xe0ea, fontFamily: 'Phosphor');
  static const bookmarkFilled = IconData(0xe0ea, fontFamily: 'PhosphorFill');
}

/// A decorative icon at one of the design's sizes (16, 20 or 24). Always pair
/// it with visible text or a Semantics label from the caller.
class FcIcon extends StatelessWidget {
  const FcIcon(this.icon, {super.key, this.size = 20, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(
        icon,
        size: size,
        color: color ?? IconTheme.of(context).color ?? context.fc.textPrimary,
      ),
    );
  }
}

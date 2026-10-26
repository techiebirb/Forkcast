import 'package:flutter/material.dart';

/// Forkcast design tokens. Colors are copied verbatim from the design system's
/// tokens.json; read them with `context.fc`.
@immutable
class FcColors extends ThemeExtension<FcColors> {
  const FcColors({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.accent,
    required this.accentPressed,
    required this.accentSoft,
    required this.onAccent,
    required this.chipSelectedPressed,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerPressed,
    required this.dangerSoft,
    required this.onDanger,
    required this.info,
    required this.infoSoft,
    required this.scrim,
    required this.mapLand,
    required this.mapRoad,
    required this.mapPark,
    required this.mapWater,
    required this.shadowRaised,
    required this.shadowPin,
  });

  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color accent;
  final Color accentPressed;
  final Color accentSoft;
  final Color onAccent;
  final Color chipSelectedPressed;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerPressed;
  final Color dangerSoft;
  final Color onDanger;
  final Color info;
  final Color infoSoft;
  final Color scrim;
  final Color mapLand;
  final Color mapRoad;
  final Color mapPark;
  final Color mapWater;
  final List<BoxShadow> shadowRaised;
  final List<BoxShadow> shadowPin;

  /// Keyboard focus ring color. Same as accent in both themes.
  Color get focus => accent;

  /// Count badge on the Filters chip, and the edge of a selected filter chip.
  /// Same as accent / onAccent in both themes.
  Color get badge => accent;
  Color get onBadge => onAccent;
  Color get chipSelectedBorder => accent;

  static const light = FcColors(
    bg: Color(0xFFF6F5F1),
    surface: Color(0xFFFCFBF8),
    surfaceRaised: Color(0xFFFEFDFB),
    surfaceSunken: Color(0xFFEEECE6),
    border: Color(0xFFE3E0D8),
    borderStrong: Color(0xFF8A857B),
    textPrimary: Color(0xFF1E1D1A),
    textSecondary: Color(0xFF5A564E),
    textDisabled: Color(0xFFA39E94),
    accent: Color(0xFF3B6B4D),
    accentPressed: Color(0xFF2E5640),
    accentSoft: Color(0xFFE4EEE6),
    onAccent: Color(0xFFFCFBF8),
    chipSelectedPressed: Color(0xFFD6E5DA),
    success: Color(0xFF1C6A62),
    successSoft: Color(0xFFDFEEEB),
    warning: Color(0xFF875A0B),
    warningSoft: Color(0xFFFAEFD9),
    danger: Color(0xFFAF3A2D),
    dangerPressed: Color(0xFF8F2F25),
    dangerSoft: Color(0xFFFAE6E2),
    onDanger: Color(0xFFFCFBF8),
    info: Color(0xFF2E5C93),
    infoSoft: Color(0xFFE4EBF5),
    scrim: Color(0x66151412),
    mapLand: Color(0xFFEBE8E1),
    mapRoad: Color(0xFFFDFCF9),
    mapPark: Color(0xFFD9E5D6),
    mapWater: Color(0xFFD5E1E8),
    shadowRaised: [
      BoxShadow(color: Color(0x0A1E1D1A), offset: Offset(0, -1)),
      BoxShadow(
        color: Color(0x141E1D1A),
        offset: Offset(0, -8),
        blurRadius: 24,
      ),
    ],
    shadowPin: [
      BoxShadow(color: Color(0x1F1E1D1A), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x141E1D1A), offset: Offset(0, 2), blurRadius: 6),
    ],
  );

  static const dark = FcColors(
    bg: Color(0xFF151412),
    surface: Color(0xFF1C1B18),
    surfaceRaised: Color(0xFF252320),
    surfaceSunken: Color(0xFF110F0E),
    border: Color(0xFF34312C),
    borderStrong: Color(0xFF77726A),
    textPrimary: Color(0xFFEDEBE6),
    textSecondary: Color(0xFFADA89F),
    textDisabled: Color(0xFF5F5B54),
    accent: Color(0xFF8CBE9B),
    accentPressed: Color(0xFFA6D0B2),
    accentSoft: Color(0xFF203028),
    onAccent: Color(0xFF13201A),
    chipSelectedPressed: Color(0xFF2A3E33),
    success: Color(0xFF7FC6BB),
    successSoft: Color(0xFF152E2A),
    warning: Color(0xFFE2B45E),
    warningSoft: Color(0xFF30260F),
    danger: Color(0xFFF08C7E),
    dangerPressed: Color(0xFFF5A79C),
    dangerSoft: Color(0xFF3A1D18),
    onDanger: Color(0xFF1C1B18),
    info: Color(0xFF92B6E3),
    infoSoft: Color(0xFF18253A),
    scrim: Color(0x99000000),
    mapLand: Color(0xFF22201D),
    mapRoad: Color(0xFF36332E),
    mapPark: Color(0xFF1E2B22),
    mapWater: Color(0xFF17222A),
    shadowRaised: [
      BoxShadow(color: Color(0x0FFFFFFF), offset: Offset(0, -1)),
      BoxShadow(
        color: Color(0x80000000),
        offset: Offset(0, -8),
        blurRadius: 24,
      ),
    ],
    shadowPin: [
      BoxShadow(color: Color(0x99000000), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 6),
    ],
  );

  @override
  FcColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? accent,
    Color? accentPressed,
    Color? accentSoft,
    Color? onAccent,
    Color? chipSelectedPressed,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? dangerPressed,
    Color? dangerSoft,
    Color? onDanger,
    Color? info,
    Color? infoSoft,
    Color? scrim,
    Color? mapLand,
    Color? mapRoad,
    Color? mapPark,
    Color? mapWater,
    List<BoxShadow>? shadowRaised,
    List<BoxShadow>? shadowPin,
  }) {
    return FcColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      accent: accent ?? this.accent,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      chipSelectedPressed: chipSelectedPressed ?? this.chipSelectedPressed,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      dangerPressed: dangerPressed ?? this.dangerPressed,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      onDanger: onDanger ?? this.onDanger,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      scrim: scrim ?? this.scrim,
      mapLand: mapLand ?? this.mapLand,
      mapRoad: mapRoad ?? this.mapRoad,
      mapPark: mapPark ?? this.mapPark,
      mapWater: mapWater ?? this.mapWater,
      shadowRaised: shadowRaised ?? this.shadowRaised,
      shadowPin: shadowPin ?? this.shadowPin,
    );
  }

  @override
  FcColors lerp(ThemeExtension<FcColors>? other, double t) {
    if (other is! FcColors) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return FcColors(
      bg: mix(bg, other.bg),
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      surfaceSunken: mix(surfaceSunken, other.surfaceSunken),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textDisabled: mix(textDisabled, other.textDisabled),
      accent: mix(accent, other.accent),
      accentPressed: mix(accentPressed, other.accentPressed),
      accentSoft: mix(accentSoft, other.accentSoft),
      onAccent: mix(onAccent, other.onAccent),
      chipSelectedPressed: mix(chipSelectedPressed, other.chipSelectedPressed),
      success: mix(success, other.success),
      successSoft: mix(successSoft, other.successSoft),
      warning: mix(warning, other.warning),
      warningSoft: mix(warningSoft, other.warningSoft),
      danger: mix(danger, other.danger),
      dangerPressed: mix(dangerPressed, other.dangerPressed),
      dangerSoft: mix(dangerSoft, other.dangerSoft),
      onDanger: mix(onDanger, other.onDanger),
      info: mix(info, other.info),
      infoSoft: mix(infoSoft, other.infoSoft),
      scrim: mix(scrim, other.scrim),
      mapLand: mix(mapLand, other.mapLand),
      mapRoad: mix(mapRoad, other.mapRoad),
      mapPark: mix(mapPark, other.mapPark),
      mapWater: mix(mapWater, other.mapWater),
      shadowRaised: BoxShadow.lerpList(shadowRaised, other.shadowRaised, t)!,
      shadowPin: BoxShadow.lerpList(shadowPin, other.shadowPin, t)!,
    );
  }
}

extension FcThemeContext on BuildContext {
  FcColors get fc =>
      Theme.of(this).extension<FcColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? FcColors.dark
          : FcColors.light);
}

/// 4pt base, 8pt rhythm.
abstract final class FcSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;
}

abstract final class FcRadius {
  static const double sm = 6;
  static const double input = 12;
  static const double card = 16;
  static const double sheet = 24;
  static const double pill = 9999;
}

/// Minimum touch target (2.75rem at default size).
const double kFcTargetMin = 44;

const String kFcFontFamily = 'Plus Jakarta Sans';

/// Type scale from tokens.json. Colors are applied by the theme or the call
/// site; line height is written as a ratio of the font size.
abstract final class FcText {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
    fontFamily: kFcFontFamily,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.64,
  );
  static const TextStyle title = TextStyle(
    fontFamily: kFcFontFamily,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.24,
  );
  static const TextStyle heading = TextStyle(
    fontFamily: kFcFontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    fontFamily: kFcFontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle bodySm = TextStyle(
    fontFamily: kFcFontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle label = TextStyle(
    fontFamily: kFcFontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: kFcFontFamily,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
  );

  /// Wordmark in the app bar: 20/28, 700, -0.01em.
  static const TextStyle wordmark = TextStyle(
    fontFamily: kFcFontFamily,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  /// Turns on tabular numerals. Use for every price, distance, count and macro.
  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: _tabular);
}

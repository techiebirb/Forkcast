// Forkcast design tokens. Values are copied from design/tokens.json; change
// them there first, then here and in flaskServer/static/tokens.css.
import 'package:flutter/material.dart';

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

  Color get focus => accent;

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
      BoxShadow(
        color: Color(0x1F1E1D1A),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: Color(0x141E1D1A),
        offset: Offset(0, 2),
        blurRadius: 6,
      ),
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
      BoxShadow(
        color: Color(0x99000000),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
      BoxShadow(
        color: Color(0x66000000),
        offset: Offset(0, 2),
        blurRadius: 6,
      ),
    ],
  );

  @override
  FcColors copyWith() => this;

  @override
  FcColors lerp(FcColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return FcColors(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textDisabled: c(textDisabled, other.textDisabled),
      accent: c(accent, other.accent),
      accentPressed: c(accentPressed, other.accentPressed),
      accentSoft: c(accentSoft, other.accentSoft),
      onAccent: c(onAccent, other.onAccent),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      warning: c(warning, other.warning),
      warningSoft: c(warningSoft, other.warningSoft),
      danger: c(danger, other.danger),
      dangerPressed: c(dangerPressed, other.dangerPressed),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      onDanger: c(onDanger, other.onDanger),
      info: c(info, other.info),
      infoSoft: c(infoSoft, other.infoSoft),
      scrim: c(scrim, other.scrim),
      mapLand: c(mapLand, other.mapLand),
      mapRoad: c(mapRoad, other.mapRoad),
      mapPark: c(mapPark, other.mapPark),
      mapWater: c(mapWater, other.mapWater),
      shadowRaised: t < 0.5 ? shadowRaised : other.shadowRaised,
      shadowPin: t < 0.5 ? shadowPin : other.shadowPin,
    );
  }
}

/// 4pt base, 8pt rhythm. Screen gutter is s4; sheet gutter s5.
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

abstract final class FcSize {
  static const double targetMin = 44;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
}

abstract final class FcMotion {
  static const fast = Duration(milliseconds: 120);
  static const sheet = Duration(milliseconds: 280);
  static const ease = Cubic(0.2, 0, 0, 1);

  /// Zero when the user asked for reduced motion.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : d;
}

extension FcContext on BuildContext {
  FcColors get fc => Theme.of(this).extension<FcColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

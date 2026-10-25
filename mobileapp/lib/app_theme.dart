import 'package:flutter/material.dart';

import 'theme/fc_tokens.dart';

export 'theme/fc_tokens.dart';

ThemeData buildLightTheme() => _buildTheme(FcColors.light, Brightness.light);

ThemeData buildDarkTheme() => _buildTheme(FcColors.dark, Brightness.dark);

ThemeData _buildTheme(FcColors c, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.accentSoft,
    onPrimaryContainer: c.accentPressed,
    secondary: c.accent,
    onSecondary: c.onAccent,
    secondaryContainer: c.accentSoft,
    onSecondaryContainer: c.accentPressed,
    error: c.danger,
    onError: c.onDanger,
    errorContainer: c.dangerSoft,
    onErrorContainer: c.danger,
    surface: c.surface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    surfaceContainerLowest: c.bg,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surfaceRaised,
    surfaceContainerHigh: c.surfaceRaised,
    surfaceContainerHighest: c.surfaceSunken,
    outline: c.borderStrong,
    outlineVariant: c.border,
    shadow: Colors.black,
    scrim: c.scrim,
    inverseSurface: c.textPrimary,
    onInverseSurface: c.bg,
    inversePrimary: c.accentSoft,
    surfaceTint: Colors.transparent,
  );

  final textTheme = TextTheme(
    displayLarge: FcText.display,
    displayMedium: FcText.display,
    displaySmall: FcText.title,
    headlineLarge: FcText.display,
    headlineMedium: FcText.display,
    headlineSmall: FcText.title,
    titleLarge: FcText.heading,
    titleMedium: FcText.body.copyWith(fontWeight: FontWeight.w600),
    titleSmall: FcText.label,
    bodyLarge: FcText.body,
    bodyMedium: FcText.body,
    bodySmall: FcText.bodySm,
    labelLarge: FcText.label,
    labelMedium: FcText.caption,
    labelSmall: FcText.caption,
  ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

  const pill = StadiumBorder();
  OutlineInputBorder field(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(FcRadius.input),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    fontFamily: kFcFontFamily,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    extensions: [c],
    dividerColor: c.border,
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: FcText.wordmark.copyWith(color: c.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FcRadius.card),
        side: BorderSide(color: c.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceRaised,
      hintStyle: FcText.body.copyWith(color: c.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: FcSpace.s3,
        vertical: FcSpace.s3,
      ),
      border: field(c.borderStrong),
      enabledBorder: field(c.borderStrong),
      focusedBorder: field(c.accent, 2),
      errorBorder: field(c.danger),
      focusedErrorBorder: field(c.danger, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(kFcTargetMin, kFcTargetMin),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: pill,
        textStyle: FcText.label,
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        disabledBackgroundColor: c.surfaceSunken,
        disabledForegroundColor: c.textDisabled,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(kFcTargetMin, kFcTargetMin),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: pill,
        textStyle: FcText.label,
        backgroundColor: c.surfaceRaised,
        foregroundColor: c.textPrimary,
        side: BorderSide(color: c.borderStrong),
        disabledForegroundColor: c.textDisabled,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(kFcTargetMin, kFcTargetMin),
        shape: pill,
        textStyle: FcText.label,
        foregroundColor: c.accent,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(kFcTargetMin, kFcTargetMin),
        foregroundColor: c.textSecondary,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(c.surfaceRaised),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? c.accent
            : c.borderStrong,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: c.surfaceRaised,
      modalBarrierColor: c.scrim,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(FcRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FcRadius.card),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.textPrimary,
      contentTextStyle: FcText.bodySm.copyWith(color: c.bg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FcRadius.input),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.surfaceSunken,
    ),
  );
}

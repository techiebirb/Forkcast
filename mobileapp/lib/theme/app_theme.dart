import 'package:flutter/material.dart';

import 'tokens.dart';

const String kFontFamily = 'PlusJakartaSans';

/// Type scale from the design system. Sizes are logical px and follow the
/// system text scale.
///
/// display → displaySmall, title → headlineSmall, app bar → titleLarge,
/// heading → titleMedium, dish name → titleSmall, body → bodyLarge,
/// body-sm → bodyMedium, caption → bodySmall, label → labelLarge,
/// tab label → labelSmall.
TextTheme _textTheme(FcColors c) {
  TextStyle s(double size, double line, FontWeight w,
          {double tracking = 0, Color? color}) =>
      TextStyle(
        fontFamily: kFontFamily,
        fontSize: size,
        height: line / size,
        fontWeight: w,
        letterSpacing: tracking * size,
        color: color ?? c.textPrimary,
      );
  return TextTheme(
    displaySmall: s(32, 40, FontWeight.w700, tracking: -0.02),
    headlineSmall: s(24, 32, FontWeight.w700, tracking: -0.01),
    titleLarge: s(20, 28, FontWeight.w700, tracking: -0.01),
    titleMedium: s(18, 24, FontWeight.w600),
    titleSmall: s(16, 24, FontWeight.w600),
    bodyLarge: s(16, 24, FontWeight.w400),
    bodyMedium: s(14, 20, FontWeight.w400),
    bodySmall: s(13, 18, FontWeight.w500, color: c.textSecondary),
    labelLarge: s(14, 20, FontWeight.w600),
    labelMedium: s(13, 18, FontWeight.w600),
    labelSmall: s(12, 16, FontWeight.w600),
  );
}

extension FcTextStyle on TextStyle {
  /// Tabular numerals, for every price, distance, count and nutrition value.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

ThemeData buildAppTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? FcColors.dark : FcColors.light;
  final text = _textTheme(c);
  const pill = StadiumBorder();

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
    tertiary: c.info,
    onTertiary: c.surface,
    error: c.danger,
    onError: c.onDanger,
    errorContainer: c.dangerSoft,
    onErrorContainer: c.danger,
    surface: c.surface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    surfaceContainerLowest: c.surfaceRaised,
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
  );

  WidgetStateProperty<Color?> pressed(Color normal, Color down,
          {Color? disabled}) =>
      WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return disabled;
        if (s.contains(WidgetState.pressed)) return down;
        return normal;
      });

  final buttonText = WidgetStatePropertyAll(text.labelLarge);
  const buttonPadding = WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  );
  const buttonMin = WidgetStatePropertyAll(
    Size(FcSize.targetMin, FcSize.targetMin),
  );
  const buttonShape = WidgetStatePropertyAll<OutlinedBorder>(pill);

  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(FcRadius.input),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [c],
    fontFamily: kFontFamily,
    textTheme: text,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.border,
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    splashFactory: NoSplash.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: FcSpace.s2,
      toolbarHeight: 56,
      titleTextStyle: text.titleLarge,
      iconTheme: IconThemeData(color: c.textSecondary, size: FcSize.iconMd),
      actionsIconTheme:
          IconThemeData(color: c.textSecondary, size: FcSize.iconMd),
    ),
    iconTheme: IconThemeData(color: c.textSecondary, size: FcSize.iconMd),
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
    // Primary button.
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor:
            pressed(c.accent, c.accentPressed, disabled: c.surfaceSunken),
        foregroundColor:
            pressed(c.onAccent, c.onAccent, disabled: c.textDisabled),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        textStyle: buttonText,
        padding: buttonPadding,
        minimumSize: buttonMin,
        shape: buttonShape,
        iconSize: const WidgetStatePropertyAll(FcSize.iconMd),
      ),
    ),
    // Secondary button.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor:
            pressed(c.surfaceRaised, c.surfaceSunken, disabled: c.surfaceSunken),
        foregroundColor:
            pressed(c.textPrimary, c.textPrimary, disabled: c.textDisabled),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStateProperty.resolveWith((s) => BorderSide(
              color: s.contains(WidgetState.disabled)
                  ? Colors.transparent
                  : c.borderStrong,
            )),
        textStyle: buttonText,
        padding: buttonPadding,
        minimumSize: buttonMin,
        shape: buttonShape,
        iconSize: const WidgetStatePropertyAll(FcSize.iconMd),
      ),
    ),
    // Ghost button and links.
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        backgroundColor: pressed(Colors.transparent, c.accentSoft),
        foregroundColor: pressed(c.accent, c.accent, disabled: c.textDisabled),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: buttonText,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: FcSpace.s2),
        ),
        minimumSize: buttonMin,
        shape: buttonShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return c.textDisabled;
          if (s.contains(WidgetState.selected)) return c.accent;
          return c.textSecondary;
        }),
        backgroundColor: pressed(Colors.transparent, c.accentSoft),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        minimumSize: buttonMin,
        iconSize: const WidgetStatePropertyAll(FcSize.iconMd),
        shape: buttonShape,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceRaised,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: FcSpace.s3,
        vertical: FcSpace.s3,
      ),
      hintStyle: text.bodyLarge!.copyWith(color: c.textSecondary),
      labelStyle: text.labelLarge,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      suffixStyle: text.bodyMedium!
          .copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
      helperStyle: text.bodySmall,
      errorStyle: text.bodySmall!.copyWith(color: c.danger),
      prefixIconColor: c.textSecondary,
      suffixIconColor: c.textSecondary,
      border: inputBorder(c.borderStrong),
      enabledBorder: inputBorder(c.borderStrong),
      focusedBorder: inputBorder(c.accent, 2),
      errorBorder: inputBorder(c.danger, 2),
      focusedErrorBorder: inputBorder(c.danger, 2),
      disabledBorder: inputBorder(c.border),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accentSoft,
      selectionHandleColor: c.accent,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? c.surfaceRaised
              : c.surfaceSunken,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? c.textPrimary
              : c.textSecondary,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: c.surfaceSunken)),
        textStyle: buttonText,
        minimumSize: buttonMin,
        shape: buttonShape,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      selectedIcon: const SizedBox.shrink(),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(c.surfaceRaised),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.accent : c.borderStrong,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbIcon: const WidgetStatePropertyAll(null),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceRaised,
      selectedColor: c.accentSoft,
      disabledColor: c.surfaceSunken,
      checkmarkColor: c.accentPressed,
      labelStyle: text.labelLarge,
      side: BorderSide(color: c.borderStrong),
      shape: pill,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      showCheckmark: false,
      pressElevation: 0,
      elevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: c.scrim,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: c.borderStrong,
      dragHandleSize: const Size(36, 4),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(FcRadius.sheet)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      barrierColor: c.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FcRadius.sheet),
      ),
      titleTextStyle: text.titleMedium,
      contentTextStyle: text.bodyMedium!.copyWith(color: c.textSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.textPrimary,
      contentTextStyle: text.bodyMedium!.copyWith(color: c.bg),
      actionTextColor: c.accentSoft,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FcRadius.input),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accent,
      linearTrackColor: c.surfaceSunken,
      circularTrackColor: Colors.transparent,
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(FcRadius.pill),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.textSecondary,
      textColor: c.textPrimary,
      titleTextStyle: text.titleSmall,
      subtitleTextStyle: text.bodyMedium!.copyWith(color: c.textSecondary),
      minVerticalPadding: FcSpace.s3,
      contentPadding: const EdgeInsets.symmetric(horizontal: FcSpace.s4),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: c.textPrimary,
      unselectedLabelColor: c.textSecondary,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.labelLarge,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: ShapeDecoration(
        color: c.surfaceRaised,
        shape: StadiumBorder(side: BorderSide(color: c.borderStrong)),
      ),
    ),
    focusColor: c.accentSoft,
    hoverColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}

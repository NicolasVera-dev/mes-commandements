import 'package:flutter/material.dart';

class AppTheme {
  static const Color seedColor = Color(0xFF7C4DFF);

  static ThemeData lightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[
        const AppSemanticColors.light(),
      ],
    );
  }

  static ThemeData darkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[
        const AppSemanticColors.dark(),
      ],
    );
  }
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color completedCardBackground;
  final Color completedCardBorder;
  final Color completedCardIcon;
  final Color successBackground;
  final Color successIndicator;
  final Color failedBackground;
  final Color failedIndicator;
  final Color currentBackground;
  final Color currentIndicator;
  final Color progressLow;
  final Color progressMedium;
  final Color progressHigh;

  const AppSemanticColors({
    required this.completedCardBackground,
    required this.completedCardBorder,
    required this.completedCardIcon,
    required this.successBackground,
    required this.successIndicator,
    required this.failedBackground,
    required this.failedIndicator,
    required this.currentBackground,
    required this.currentIndicator,
    required this.progressLow,
    required this.progressMedium,
    required this.progressHigh,
  });

  const AppSemanticColors.light()
      : completedCardBackground = const Color(0xFFEAF6ED),
        completedCardBorder = const Color(0xFF2E7D32),
        completedCardIcon = const Color(0xFF1B5E20),
        successBackground = const Color(0xFFEAF6ED),
        successIndicator = const Color(0xFF1B5E20),
        failedBackground = const Color(0xFFFDECEC),
        failedIndicator = const Color(0xFFB3261E),
        currentBackground = const Color(0xFFE9EDF3),
        currentIndicator = const Color(0xFF4B5563),
        progressLow = const Color(0xFFB3261E),
        progressMedium = const Color(0xFFE65100),
        progressHigh = const Color(0xFF2E7D32);

  const AppSemanticColors.dark()
      : completedCardBackground = const Color(0x1F4CAF50),
        completedCardBorder = const Color(0x8A9BE7A5),
        completedCardIcon = const Color(0xFF9BE7A5),
        successBackground = const Color(0x1F4CAF50),
        successIndicator = const Color(0xFF9BE7A5),
        failedBackground = const Color(0x1FD32F2F),
        failedIndicator = const Color(0xFFFF8A80),
        currentBackground = const Color(0x245E6268),
        currentIndicator = const Color(0xFFB0B7C3),
        progressLow = const Color(0xFFFF8A80),
        progressMedium = const Color(0xFFFFB74D),
        progressHigh = const Color(0xFF9BE7A5);

  @override
  AppSemanticColors copyWith({
    Color? completedCardBackground,
    Color? completedCardBorder,
    Color? completedCardIcon,
    Color? successBackground,
    Color? successIndicator,
    Color? failedBackground,
    Color? failedIndicator,
    Color? currentBackground,
    Color? currentIndicator,
    Color? progressLow,
    Color? progressMedium,
    Color? progressHigh,
  }) {
    return AppSemanticColors(
      completedCardBackground:
          completedCardBackground ?? this.completedCardBackground,
      completedCardBorder: completedCardBorder ?? this.completedCardBorder,
      completedCardIcon: completedCardIcon ?? this.completedCardIcon,
      successBackground: successBackground ?? this.successBackground,
      successIndicator: successIndicator ?? this.successIndicator,
      failedBackground: failedBackground ?? this.failedBackground,
      failedIndicator: failedIndicator ?? this.failedIndicator,
      currentBackground: currentBackground ?? this.currentBackground,
      currentIndicator: currentIndicator ?? this.currentIndicator,
      progressLow: progressLow ?? this.progressLow,
      progressMedium: progressMedium ?? this.progressMedium,
      progressHigh: progressHigh ?? this.progressHigh,
    );
  }

  @override
  AppSemanticColors lerp(
    covariant ThemeExtension<AppSemanticColors>? other,
    double t,
  ) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      completedCardBackground:
          Color.lerp(completedCardBackground, other.completedCardBackground, t)!,
      completedCardBorder:
          Color.lerp(completedCardBorder, other.completedCardBorder, t)!,
      completedCardIcon:
          Color.lerp(completedCardIcon, other.completedCardIcon, t)!,
      successBackground:
          Color.lerp(successBackground, other.successBackground, t)!,
      successIndicator:
          Color.lerp(successIndicator, other.successIndicator, t)!,
      failedBackground:
          Color.lerp(failedBackground, other.failedBackground, t)!,
      failedIndicator:
          Color.lerp(failedIndicator, other.failedIndicator, t)!,
      currentBackground:
          Color.lerp(currentBackground, other.currentBackground, t)!,
      currentIndicator:
          Color.lerp(currentIndicator, other.currentIndicator, t)!,
      progressLow: Color.lerp(progressLow, other.progressLow, t)!,
      progressMedium: Color.lerp(progressMedium, other.progressMedium, t)!,
      progressHigh: Color.lerp(progressHigh, other.progressHigh, t)!,
    );
  }
}

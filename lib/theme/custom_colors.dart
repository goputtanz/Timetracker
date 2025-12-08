import 'package:flutter/material.dart';

@immutable
class SpecialColors extends ThemeExtension<SpecialColors> {
  final Color? playButtonColor;
  final Color? pauseButtonColor;
  final Color? breakIndicatorColor;
  final Color? stopButtonColor;
  final Color? premiumButtonColor;
  final Color? premiumOutlineColor;
  final Color? customSurfaceColor;
  final Color? warningColor;

  const SpecialColors({
    required this.playButtonColor,
    required this.pauseButtonColor,
    required this.breakIndicatorColor,
    required this.stopButtonColor,
    required this.premiumButtonColor,
    required this.premiumOutlineColor,
    required this.customSurfaceColor,
    required this.warningColor,
  });

  @override
  SpecialColors copyWith({
    Color? playButtonColor,
    Color? pauseButtonColor,
    Color? breakIndicatorColor,
    Color? stopButtonColor,
    Color? premiumButtonColor,
    Color? premiumOutlineColor,
    Color? customSurfaceColor,
    Color? warningColor,
  }) {
    return SpecialColors(
      playButtonColor: playButtonColor ?? this.playButtonColor,
      pauseButtonColor: pauseButtonColor ?? this.pauseButtonColor,
      breakIndicatorColor: breakIndicatorColor ?? this.breakIndicatorColor,
      stopButtonColor: stopButtonColor ?? this.stopButtonColor,
      premiumButtonColor: premiumButtonColor ?? this.premiumButtonColor,
      premiumOutlineColor: premiumOutlineColor ?? this.premiumOutlineColor,
      customSurfaceColor: customSurfaceColor ?? this.customSurfaceColor,
      warningColor: warningColor ?? this.warningColor,
    );
  }

  @override
  SpecialColors lerp(ThemeExtension<SpecialColors>? other, double t) {
    if (other is! SpecialColors) {
      return this;
    }
    return SpecialColors(
      playButtonColor: Color.lerp(playButtonColor, other.playButtonColor, t),
      pauseButtonColor: Color.lerp(pauseButtonColor, other.pauseButtonColor, t),
      breakIndicatorColor: Color.lerp(
        breakIndicatorColor,
        other.breakIndicatorColor,
        t,
      ),
      stopButtonColor: Color.lerp(stopButtonColor, other.stopButtonColor, t),
      premiumButtonColor: Color.lerp(
        premiumButtonColor,
        other.premiumButtonColor,
        t,
      ),
      premiumOutlineColor: Color.lerp(
        premiumOutlineColor,
        other.premiumOutlineColor,
        t,
      ),
      customSurfaceColor: Color.lerp(
        customSurfaceColor,
        other.customSurfaceColor,
        t,
      ),
      warningColor: Color.lerp(warningColor, other.warningColor, t),
    );
  }
}

const customColorsLight = SpecialColors(
  playButtonColor: Color(0XFF00BC7C),
  pauseButtonColor: Color(0xFFD4183D),
  breakIndicatorColor: Color(0xFFF59E0B),
  stopButtonColor: Color(0xFFD4183D),
  premiumButtonColor: Color(0xFF9359FF),
  premiumOutlineColor: Color(0xFF000000),
  customSurfaceColor: Color(0xFFE0E0E0),
  warningColor: Color(0xFFD4183D),
);

const customColorsDark = SpecialColors(
  playButtonColor: Color(0xFF10B981),
  pauseButtonColor: Color(0xFF82181A),
  breakIndicatorColor: Color(0xFFF59E0B),
  stopButtonColor: Color(0xFFD4183D),
  premiumButtonColor: Color(0xFF8B5CF6),
  premiumOutlineColor: Color(0xFF000000),
  customSurfaceColor: Color(0xFF262626),
  warningColor: Color(0xFFD4183D),
);

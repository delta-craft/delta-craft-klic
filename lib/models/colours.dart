import 'package:flutter/material.dart';

Color primary = colourFromHex("#0067c4");
Color background = colourFromHex("#3b3b3b");
Color backgroundNav = colourFromHex("#2b2b2b");
Color primaryiOS = colourFromHex("#3077b7");

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}

MaterialColor colourTheme = createMaterialColour(primary);

MaterialColor createMaterialColour(Color colour) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = <int, Color>{};
  final int r = colour.red, g = colour.green, b = colour.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  strengths.forEach((strength) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  });
  return MaterialColor(colour.value, swatch);
}

Color colourFromHex(String hexColour) {
  final hexCode = hexColour.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}

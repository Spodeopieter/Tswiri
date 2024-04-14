import 'package:flutter/material.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF9F4200),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFFFDBCB),
  onPrimaryContainer: Color(0xFF341100),
  secondary: Color(0xFF765849),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFFFDBCB),
  onSecondaryContainer: Color(0xFF2C160B),
  tertiary: Color(0xFF656031),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFECE4AA),
  onTertiaryContainer: Color(0xFF1F1C00),
  error: Color(0xFFBA1A1A),
  errorContainer: Color(0xFFFFDAD6),
  onError: Color(0xFFFFFFFF),
  onErrorContainer: Color(0xFF410002),
  background: Color(0xFFFFFBFF),
  onBackground: Color(0xFF201A18),
  surface: Color(0xFFFFFBFF),
  onSurface: Color(0xFF201A18),
  surfaceVariant: Color(0xFFF4DED5),
  onSurfaceVariant: Color(0xFF52443D),
  outline: Color(0xFF85736C),
  onInverseSurface: Color(0xFFFBEEE9),
  inverseSurface: Color(0xFF362F2C),
  inversePrimary: Color(0xFFFFB692),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF9F4200),
  outlineVariant: Color(0xFFD7C2B9),
  scrim: Color(0xFF000000),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFFB692),
  onPrimary: Color(0xFF552000),
  primaryContainer: Color(0xFF793100),
  onPrimaryContainer: Color(0xFFFFDBCB),
  secondary: Color(0xFFE6BEAC),
  onSecondary: Color(0xFF432A1E),
  secondaryContainer: Color(0xFF5C4033),
  onSecondaryContainer: Color(0xFFFFDBCB),
  tertiary: Color(0xFFD0C890),
  onTertiary: Color(0xFF353107),
  tertiaryContainer: Color(0xFF4C481C),
  onTertiaryContainer: Color(0xFFECE4AA),
  error: Color(0xFFFFB4AB),
  errorContainer: Color(0xFF93000A),
  onError: Color(0xFF690005),
  onErrorContainer: Color(0xFFFFDAD6),
  background: Color(0xFF201A18),
  onBackground: Color(0xFFEDE0DB),
  surface: Color(0xFF201A18),
  onSurface: Color(0xFFEDE0DB),
  surfaceVariant: Color(0xFF52443D),
  onSurfaceVariant: Color(0xFFD7C2B9),
  outline: Color(0xFFA08D85),
  onInverseSurface: Color(0xFF201A18),
  inverseSurface: Color(0xFFEDE0DB),
  inversePrimary: Color(0xFF9F4200),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFFFFB692),
  outlineVariant: Color(0xFF52443D),
  scrim: Color(0xFF000000),
);

ThemeData get lightTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    snackBarTheme: snackBarTheme,
    inputDecorationTheme: inputDecorationTheme,
  );
}

ThemeData get darkTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    snackBarTheme: snackBarTheme,
    inputDecorationTheme: inputDecorationTheme,
  );
}

SnackBarThemeData get snackBarTheme {
  return SnackBarThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

InputDecorationTheme get inputDecorationTheme {
  return const InputDecorationTheme(
    border: OutlineInputBorder(),
  );
}

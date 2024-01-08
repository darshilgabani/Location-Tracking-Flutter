import 'package:flutter/material.dart';
import 'package:location_tracking_flutter/utils/colors.dart';

ThemeData appThemeData = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  useMaterial3: true,
  textSelectionTheme: TextSelectionThemeData(cursorColor: themeDarkOrangeColor, selectionColor: themeOrangeColor)
);

TextStyle appBarTextStyle = TextStyle(color: textWhiteColor);

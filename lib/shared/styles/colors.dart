import 'package:flutter/material.dart';

extension ThemeExtension on ThemeData {
  Color get categorySelectedColor => brightness == Brightness.light
      ? Colors.blue // Light mode selected color
      : Colors.lightBlue; // Dark mode selected color

// Add more custom theme colors as needed
}

class AppColors {
  static final primaryColor = Color(0xff347bfa);
  static final blackColor = Colors.black;
  static final whiteColor = Colors.white;
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColor {
  static const red = Color(0xFFCD2121);
  static const orange = Color(0xFFFFB100);
  static const green = Color(0xFF006425);
  static const blue = Color(0xFF14279B);
  static const purple = Color(0xFFA207D8);
  static const black = Color(0xFF121212);
  static const ashGrey = Color(0xFF858E96);
  static const grey = Color(0xFFF1F1F1);
  static const white = Color(0xFFF5F6F8);
}

class AppPalette {
  static const MaterialColor blue = MaterialColor(
    0xFF14279B,
    <int, Color>{
      50: Color(0xFFE3E6F7),
      100: Color(0xFFBDC4EB),
      200: Color(0xFF949EE0),
      300: Color(0xFF6A78D4),
      400: Color(0xFF4C5DCB),
      500: Color(0xFF2F42C1),
      600: Color(0xFF1D35B5),
      700: Color(0xFF14279B),
      800: Color(0xFF101F76),
      900: Color(0xFF0C1858),
    },
  );
}

TextStyle heading1 = GoogleFonts.poppins(
  color: AppColor.black,
  fontWeight: bold,
  fontSize: 54,
);

TextStyle heading2 = GoogleFonts.poppins(
  color: AppColor.black,
  fontWeight: semibold,
  fontSize: 42,
);

TextStyle heading3 = GoogleFonts.poppins(
  color: AppColor.black,
  fontWeight: medium,
  fontSize: 34,
);

TextStyle heading4 = GoogleFonts.poppins(
  color: AppColor.black,
  fontWeight: regular,
  fontSize: 28,
);

TextStyle heading5 = GoogleFonts.poppins(
  color: AppColor.black,
  fontWeight: light,
  fontSize: 20,
);

TextStyle body1 = GoogleFonts.poppins(
  color: AppColor.black,
  fontWeight: bold,
  fontSize: 16,
);

TextStyle body2 = GoogleFonts.poppins(
  color: AppColor.black,
  fontWeight: bold,
  fontSize: 14,
);

TextStyle paragraph1 = GoogleFonts.poppins(
  color: AppColor.black,
  fontWeight: semibold,
  fontSize: 16,
);

TextStyle paragraph2 = GoogleFonts.poppins(
  color: AppColor.black,
  fontWeight: medium,
  fontSize: 14,
);

TextStyle paragraph3 = GoogleFonts.poppins(
  color: AppColor.black,
  fontWeight: regular,
  fontSize: 12,
);

FontWeight light = FontWeight.w300;
FontWeight regular = FontWeight.w400;
FontWeight medium = FontWeight.w500;
FontWeight semibold = FontWeight.w600;
FontWeight bold = FontWeight.w700;
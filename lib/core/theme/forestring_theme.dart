import 'package:flutter/material.dart';

const Color primaryColor = Color(0xff003717);
const Color secondaryColor = Color(0xff708C7A);
const Color ivoryColor = Color(0xffFDF8E7);

const TextStyle forestringTextStyle = TextStyle(
  color: Colors.black,
  fontFamily: 'ELAND',
  fontWeight: FontWeight.w300,
);

ThemeData buildForestringTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
    ),
    fontFamily: 'ELAND',
    useMaterial3: true,
  );
}

import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  const CustomText({
    required this.text,
    super.key,
    this.fontSize = 12,
    this.fontFamily,
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.letterSpacing = 0,
    this.fontStyle = FontStyle.normal,
    this.maxLines,
    this.overflow,
    this.color,
  });

  final String text;
  final double fontSize;
  final double letterSpacing;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final String? fontFamily;
  final FontStyle fontStyle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
      ),
    );
  }
}

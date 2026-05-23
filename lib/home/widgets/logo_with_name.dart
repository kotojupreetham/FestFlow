//logo_with_name.dart

import 'package:flutter/material.dart';

class LogoWithName extends StatelessWidget {
  final String logoPath; // Path to the logo image
  final String appName;
  final double logoSize;
  final TextStyle? textStyle;

  const LogoWithName({
    Key? key,
    required this.logoPath,
    this.appName = "FestFlow",
    this.logoSize = 80.0,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', width: logoSize, height: logoSize), // Logo
        SizedBox(height: 10),
        Text(
          appName,
          style: textStyle ??
              TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
        ),
      ],
    );
  }
}

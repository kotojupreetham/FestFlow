//loading_bar.dart

import 'package:flutter/material.dart';

class LoadingBar extends StatelessWidget {
  final double size;
  final Color color;

  const LoadingBar({Key? key, this.size = 50.0, this.color = Colors.orange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(color),
          strokeWidth: 4.0,
        ),
      ),
    );
  }
}

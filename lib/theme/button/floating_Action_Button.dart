import 'package:flutter/material.dart';

Widget customFloatingActionButton({
  required VoidCallback onPressed,
  IconData icon = Icons.close,
}) {
  return SizedBox(
    width: 42, // Custom small size
    height: 42,
    child: FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Colors.red,
      elevation: 10.0,
      shape: const CircleBorder(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner thin ring
          Container(
            width: 34, // Smaller inner ring
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          // Icon
          Icon(icon, color: Colors.white, size: 24), // Smaller icon
        ],
      ),
    ),
  );
}


//floating_menu.dart


import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/member_list.dart';
import '../screens/member_event_page.dart';
import '../screens/settings/settings_page.dart';
import '../screens/settings/chat_screen.dart'; // MemberChatScreen
import '../screens/member_analytics_screen.dart';

class FloatingMenu extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String eventCode;

  const FloatingMenu({
    Key? key,
    required this.isOpen,
    required this.eventCode,
    required this.onClose, // New required parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return SizedBox.shrink(); // Hide menu when not open

    return Stack(
      children: [
        // Blurred Background
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        ),

        // Floating Menu Buttons (Square Shape)
        Positioned(
          bottom: 400, left: 50, // Top Left Corner
          child: _menuButton(Icons.event, "Sub-Events", context, () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MemberEventPage(eventCode: eventCode)),
                  (route) => false,
            );
          }),
        ),
        Positioned(
          bottom: 400, right: 50, // Top Right Corner
          child: _menuButton(Icons.people, "Members", context, () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MemberList(eventCode: eventCode)),
                  (route) => false,
            );
          }),
        ),
        Positioned(
          bottom: 80, left: 50, // Bottom Left Corner
          child: _menuButton(Icons.chat, "Chat", context, () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MemberChatScreen(eventCode: eventCode)),
              (route) => false,
            );
          }),
        ),
        Positioned(
          bottom: 80, right: 50, // Bottom Right Corner
          child: _menuButton(Icons.analytics, "Analytics", context, () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MemberAnalyticsScreen(eventCode: eventCode)),
              (route) => false,
            );
          }),
        ),
        Positioned(
          bottom: 240,
          left: MediaQuery.of(context).size.width / 2 - 30, // Center Button
          child: _menuButton(Icons.person_add, "Guest", context, () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Guest section coming soon!")),
            );
          }),
        ),
      ],
    );
  }

   Widget _menuButton(IconData icon, String label, BuildContext context,
      VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: Colors.blue,
          child: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
        SizedBox(height: 8), // Space between button and label
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}

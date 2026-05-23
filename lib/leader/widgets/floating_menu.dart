import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/sub_events/sub_event_page.dart';
import '../screens/members/member_page.dart';
import '../screens/guest/guest_page.dart';
import '../screens/settings/chat_screen.dart';
import '../screens/analytics/analytics_screen.dart';

class FloatingMenu extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String eventCode;

  const FloatingMenu({
    Key? key,
    required this.isOpen,
    required this.eventCode,
    required this.onClose,
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

        // Floating Menu Buttons
        Positioned(
          bottom: 400, left: 50,
          child: _menuButton(Icons.event, "Events", context, () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SubEventPage(eventCode: eventCode)),
                  (route) => false,
            );
          }),
        ),
        Positioned(
          bottom: 400, right: 50,
          child: _menuButton(Icons.people, "Members", context, () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MemberPage(eventCode: eventCode)),
                  (route) => false,
            );
          }),
        ),
        Positioned(
          bottom: 80, left: 50,
          child: _menuButton(Icons.chat, "Chat", context, () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => ChatScreen(eventCode: eventCode)),
                  (route) => false,
            );
          }),
        ),
        Positioned(
          bottom: 80, right: 50,
          child: _menuButton(Icons.analytics, "Analytics", context, () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => AnalyticsScreen(eventCode: eventCode)),
                  (route) => false,
            );
          }),
        ),

        // Centered Approve Guests Button
        Positioned(
          bottom: 240,
          left: MediaQuery.of(context).size.width / 2 - 30,
          child: _menuButton(Icons.group, "Guests", context, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuestPage(eventCode: eventCode),
              ),
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
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}

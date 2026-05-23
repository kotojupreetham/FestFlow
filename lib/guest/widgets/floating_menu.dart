
//floating_menu.dart

import 'dart:ui';
import 'package:festflow/guest/screens/guest_sub_event_list.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/profile_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/settings/settings_page.dart';

/// Floating menu for the guest dashboard.
/// Contains button actions
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

  /// Launch the phone dialer with the emergency number.
  Future<void> _callEmergency() async {
    final Uri emergencyUri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(emergencyUri)) {
      await launchUrl(emergencyUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return SizedBox.shrink();

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

        // --- Profile Button ---
        Positioned(
          bottom: 400, left: 50,
          child: _menuButton(Icons.person, "Profile", context, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
          }),
        ),

        // --- Notifications Button ---
        Positioned(
          bottom: 400, right: 50,
          child: _menuButton(Icons.notifications, "Alerts", context, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()));
          }),
        ),

        // --- Settings Button ---
        Positioned(
          bottom: 80, left: 50,
          child: _menuButton(Icons.settings, "Settings", context, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
          }),
        ),

        // --- Emergency Button ---
        Positioned(
          bottom: 80, right: 50,
          child: _menuButton(Icons.emergency, "112", context, _callEmergency, buttonColor: Colors.red),
        ),

        // --- Events Button (center) ---
        Positioned(
          bottom: 240,
          left: MediaQuery.of(context).size.width / 2 - 30,
          child: _menuButton(Icons.event, "Events", context, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GuestEventDetails(eventCode: eventCode),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _menuButton(
    IconData icon,
    String label,
    BuildContext context,
    VoidCallback onPressed, {
    Color buttonColor = Colors.blue,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: label,
          backgroundColor: buttonColor,
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

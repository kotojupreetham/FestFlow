
//notification_settings.dart

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'settings_page.dart';

class NotificationSettings extends StatefulWidget {
  @override
  _NotificationSettingsState createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool chatNotifications = true;
  bool eventUpdates = true;
  bool generalAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notification Settings")),
      body: Column(
        children: [
          SwitchListTile(
            title: Text("Chat Notifications"),
            value: chatNotifications,
            onChanged: (value) {
              setState(() {
                chatNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: Text("Event Updates"),
            value: eventUpdates,
            onChanged: (value) {
              setState(() {
                eventUpdates = value;
              });
            },
          ),
          SwitchListTile(
            title: Text("General Alerts"),
            value: generalAlerts,
            onChanged: (value) {
              setState(() {
                generalAlerts = value;
              });
            },
          ),
        ],
      ),

      floatingActionButton: customFloatingActionButton(onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
                  (route) => false,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

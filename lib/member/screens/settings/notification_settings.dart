
//notification_settings.dart (Member)

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_page.dart';

class NotificationSettings extends StatefulWidget {
  @override
  _NotificationSettingsState createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool chatNotifications = true;
  bool eventUpdates = true;
  bool generalAlerts = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      DocumentSnapshot doc = await _firestore.collection("users").doc(user.email!).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> prefs = data.containsKey("notificationPrefs")
            ? Map<String, dynamic>.from(data["notificationPrefs"])
            : {};

        setState(() {
          chatNotifications = prefs["chat"] ?? true;
          eventUpdates = prefs["events"] ?? true;
          generalAlerts = prefs["general"] ?? true;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error loading notification preferences: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection("users").doc(user.email!).update({
        "notificationPrefs": {
          "chat": chatNotifications,
          "events": eventUpdates,
          "general": generalAlerts,
        }
      });
    } catch (e) {
      print("Error saving notification preferences: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notification Settings")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: SwitchListTile(
                    secondary: Icon(Icons.chat, color: Colors.green),
                    title: Text("Chat Notifications"),
                    subtitle: Text("Get notified for new chat messages"),
                    value: chatNotifications,
                    onChanged: (value) {
                      setState(() => chatNotifications = value);
                      _savePreferences();
                    },
                  ),
                ),
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: SwitchListTile(
                    secondary: Icon(Icons.event, color: Colors.blue),
                    title: Text("Sub-Event Updates"),
                    subtitle: Text("Get notified when sub-events change"),
                    value: eventUpdates,
                    onChanged: (value) {
                      setState(() => eventUpdates = value);
                      _savePreferences();
                    },
                  ),
                ),
                Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: SwitchListTile(
                    secondary: Icon(Icons.notifications, color: Colors.orange),
                    title: Text("General Alerts"),
                    subtitle: Text("Announcements from the leader"),
                    value: generalAlerts,
                    onChanged: (value) {
                      setState(() => generalAlerts = value);
                      _savePreferences();
                    },
                  ),
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

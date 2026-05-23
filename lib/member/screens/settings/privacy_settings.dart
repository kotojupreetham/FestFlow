
//privacy_settings.dart

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'settings_page.dart';

class PrivacySettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Privacy & Security")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Privacy & Security Policy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "FestFlow values your privacy and security. We ensure that your data is protected and never shared without your consent. "
              "All communications within the app are encrypted to maintain confidentiality.",
            ),
          ],
        ),
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

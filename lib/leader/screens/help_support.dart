
//help_support.dart

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'settings/settings_page.dart';

class HelpSupport extends StatelessWidget {
  final List<Map<String, String>> faqs = [
    {"question": "How do I create an event?", "answer": "Go to the Events page and tap on 'Add Event'."},
    {"question": "How do I add members?", "answer": "In 'Manage Members', you can invite users by email."},
    {"question": "How do I enable notifications?", "answer": "Go to Settings > Notifications and toggle the switches."},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Help & Support")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ...faqs.map((faq) => ExpansionTile(
                  title: Text(faq["question"]!, style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [Padding(padding: EdgeInsets.all(10), child: Text(faq["answer"]!))],
                )),
            SizedBox(height: 20), // Space before the button
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                icon: Icon(Icons.email),
                label: Text("Contact Support"),
                onPressed: () {
                  // TODO: Implement contact support functionality
                },
              ),
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

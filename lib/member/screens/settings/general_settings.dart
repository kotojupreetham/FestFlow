
//general_setting.dart

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'settings_page.dart';
class GeneralSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("General Settings")),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.language),
            title: Text("App Language"),
            subtitle: Text("English"),
            onTap: () {
              // TODO: Implement language selection
            },
          ),
          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text("Theme"),
            subtitle: Text("Light / Dark Mode"),
            onTap: () {
              // TODO: Implement theme switch
            },
          ),
          ListTile(
            leading: Icon(Icons.storage),
            title: Text("Storage Management"),
            onTap: () {
              // TODO: Implement storage management
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

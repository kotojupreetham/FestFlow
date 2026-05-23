
//account_settings.dart

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'dart:io';

class AccountSettings extends StatefulWidget {
  @override
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  File? _image;

  Future<void> _pickImage() async {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Account Settings")),
      body: Column(
        children: [
          SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null ? FileImage(_image!) : AssetImage("assets/default_profile.png") as ImageProvider,
                child: _image == null ? Icon(Icons.camera_alt, size: 30, color: Colors.white) : null,
              ),
            ),
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Change Username"),
            onTap: () {
              // TODO: Implement username change functionality
            },
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text("Change Email"),
            onTap: () {
              // TODO: Implement email change functionality
            },
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text("Change Password"),
            onTap: () {
              // TODO: Implement password change functionality
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

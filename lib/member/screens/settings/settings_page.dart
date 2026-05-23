
//settings_page.dart (Member)

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../member_dashboard.dart';
import 'account_settings.dart';
import 'general_settings.dart';
import 'notification_settings.dart';
import 'privacy_settings.dart';
import '../help_support.dart';
import 'about_page.dart';
import '../../../home/dashboard/home_page.dart';

class SettingsPage extends StatelessWidget {

  void _signOut(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Sign Out"),
        content: Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
                (route) => false,
              );
            },
            child: Text("Sign Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: ListView(
        children: [
          _buildSettingsOption(Icons.account_circle, "Account", context, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AccountSettings()));
          }, subtitle: "Username, password"),
          _buildSettingsOption(Icons.tune, "General", context, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => GeneralSettings()));
          }, subtitle: "Language, theme"),
          _buildSettingsOption(Icons.notifications, "Notifications", context, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationSettings()));
          }, subtitle: "Chat, events, alerts"),
          _buildSettingsOption(Icons.lock, "Privacy & Security", context, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacySettings()));
          }, subtitle: "Data policy"),
          _buildSettingsOption(Icons.help_outline, "Help & Support", context, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HelpSupport()));
          }, subtitle: "FAQ, contact us"),
          _buildSettingsOption(Icons.info, "About", context, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AboutPage()));
          }, subtitle: "Version, developer"),
          _buildSettingsOption(Icons.system_update, "Version", context, () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("App Version"),
                content: Text("FestFlow v1.0.0"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
                ],
              ),
            );
          }, subtitle: "v1.0.0"),
          Divider(thickness: 2),
          _buildSettingsOption(Icons.logout, "Sign Out", context, () {
            _signOut(context);
          }, color: Colors.red, subtitle: "Log out of your account"),
        ],
      ),

      floatingActionButton: customFloatingActionButton(onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MemberDashboard()),
                  (route) => false,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSettingsOption(IconData icon, String title, BuildContext context, VoidCallback onTap, {Color color = Colors.black, String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey)) : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
      onTap: onTap,
    );
  }
}

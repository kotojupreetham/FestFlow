
//account_settings.dart

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_page.dart';

class AccountSettings extends StatefulWidget {
  @override
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _currentUsername = "";
  String _currentEmail = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      DocumentSnapshot leaderDoc = await _firestore.collection("leader").doc(_user!.email).get();
      if (leaderDoc.exists && leaderDoc.data() != null) {
        Map<String, dynamic> data = leaderDoc.data() as Map<String, dynamic>;
        setState(() {
          _currentUsername = data["username"] ?? "Unknown";
          _currentEmail = _user!.email ?? "No email";
          isLoading = false;
        });
      } else {
        setState(() {
          _currentEmail = _user!.email ?? "No email";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() => isLoading = false);
    }
  }

  void _showChangeUsernameDialog() {
    final controller = TextEditingController(text: _currentUsername);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Username"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: "New Username",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String newName = controller.text.trim();
              if (newName.isEmpty) return;

              try {
                // Update in leader/{email}
                await _firestore.collection("leader").doc(_user!.email).update({"username": newName});

                // Also update in events/{eventCode} leader map
                QuerySnapshot events = await _firestore
                    .collection("leader")
                    .doc(_user!.email)
                    .collection("events")
                    .get();
                for (var doc in events.docs) {
                  await _firestore.collection("events").doc(doc.id).update({"leader.username": newName});
                }

                setState(() => _currentUsername = newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Username updated to '$newName'!")),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to update username.")),
                );
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Change Password"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPassController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Current Password", border: OutlineInputBorder()),
              ),
              SizedBox(height: 12),
              TextField(
                controller: newPassController,
                obscureText: true,
                decoration: InputDecoration(labelText: "New Password", border: OutlineInputBorder()),
              ),
              SizedBox(height: 12),
              TextField(
                controller: confirmPassController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Confirm New Password", border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String currentPass = currentPassController.text.trim();
              String newPass = newPassController.text.trim();
              String confirmPass = confirmPassController.text.trim();

              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Password must be at least 6 characters.")),
                );
                return;
              }
              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Passwords do not match.")),
                );
                return;
              }

              try {
                // Re-authenticate with current password
                AuthCredential credential = EmailAuthProvider.credential(
                  email: _user!.email!,
                  password: currentPass,
                );
                await _user!.reauthenticateWithCredential(credential);
                await _user!.updatePassword(newPass);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Password updated successfully!")),
                );
              } on FirebaseAuthException catch (e) {
                Navigator.pop(context);
                String msg = "Failed to update password.";
                if (e.code == 'wrong-password') msg = "Current password is incorrect.";
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Account"),
        content: Text(
          "Are you sure you want to delete your account? This action cannot be undone.",
          style: TextStyle(color: Colors.red[700]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Account deletion is not available yet.")),
              );
            },
            child: Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Account Settings")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SizedBox(height: 20),
                // Profile avatar (no upload — free account)
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Text(
                      _currentUsername.isNotEmpty ? _currentUsername[0].toUpperCase() : "?",
                      style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Center(
                  child: Text(_currentUsername, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Center(
                  child: Text(_currentEmail, style: TextStyle(fontSize: 14, color: Colors.grey)),
                ),
                SizedBox(height: 24),

                Divider(),

                ListTile(
                  leading: Icon(Icons.person, color: Colors.blue),
                  title: Text("Change Username"),
                  subtitle: Text(_currentUsername),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showChangeUsernameDialog,
                ),
                ListTile(
                  leading: Icon(Icons.email, color: Colors.teal),
                  title: Text("Email"),
                  subtitle: Text(_currentEmail),
                  trailing: Icon(Icons.lock, size: 16, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Email cannot be changed.")),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lock, color: Colors.orange),
                  title: Text("Change Password"),
                  subtitle: Text("••••••••"),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showChangePasswordDialog,
                ),

                Divider(),

                ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text("Delete Account", style: TextStyle(color: Colors.red)),
                  onTap: _showDeleteAccountDialog,
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

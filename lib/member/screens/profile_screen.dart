import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'member_dashboard.dart';
import '../../home/dashboard/home_page.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? eventCode;
  bool isOnline = false;
  String? username;
  Map<String, dynamic>? memberDetails;
  bool isLoading = true;
  bool isEditingUsername = false;
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEventCode();
  }

  Future<void> fetchEventCode() async {
    _user = _auth.currentUser;
    if (_user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // 1. Get user doc to get username
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.email!).get();
      if (userDoc.exists && userDoc.data() != null) {
        username = (userDoc.data() as Map<String, dynamic>)['username'] ?? 'Member';
      }

      // 2. Get event code from events subcollection
      QuerySnapshot eventSnapshots = await _firestore
          .collection('users')
          .doc(_user!.email!)
          .collection('events')
          .get();

      if (eventSnapshots.docs.isNotEmpty) {
        eventCode = eventSnapshots.docs.first.id;

        if (eventCode != null && eventCode!.isNotEmpty) {
          fetchMemberDetails(eventCode!);
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching event code: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchMemberDetails(String code) async {
    try {
      DocumentSnapshot memberDoc = await _firestore
          .collection("events")
          .doc(code)
          .collection("member")
          .doc(_user!.email!)
          .get();

      if (memberDoc.exists && memberDoc.data() != null) {
        Map<String, dynamic> data = memberDoc.data() as Map<String, dynamic>;

        setState(() {
          memberDetails = data;
          _usernameController.text = data["username"] ?? username ?? "No Name";
          isOnline = data["isOnline"] ?? false;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching member details: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> updateUsername() async {
    if (eventCode == null || _user == null) return;

    String newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;

    try {
      await _firestore
          .collection("events")
          .doc(eventCode)
          .collection("member")
          .doc(_user!.email!)
          .update({"username": newUsername});

      await _firestore.collection("users").doc(_user!.email!).update({
        "username": newUsername
      });

      setState(() {
        username = newUsername;
        if (memberDetails != null) memberDetails!["username"] = newUsername;
        isEditingUsername = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Username updated successfully!")),
      );
    } catch (e) {
      print("Error updating username: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update username.")),
      );
    }
  }

  Future<void> toggleOnlineStatus(bool value) async {
    if (eventCode == null || _user == null) return;
    
    setState(() {
      isOnline = value;
    });

    try {
      await _firestore
          .collection("events")
          .doc(eventCode)
          .collection("member")
          .doc(_user!.email!)
          .update({"isOnline": value});
          
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? "You are now Online" : "You are now Offline")),
      );
    } catch (e) {
      print("Error updating online status: $e");
      setState(() {
        isOnline = !value; // Revert on failure
      });
    }
  }

  void _logout() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayName = username ?? memberDetails?["username"] ?? "Member";

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Initial-based avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isEditingUsername
                    ? Expanded(
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: "Edit Username"),
                  ),
                )
                    : Text(
                  displayName,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(isEditingUsername ? Icons.save : Icons.edit),
                  color: isEditingUsername ? Colors.green : Colors.blue,
                  onPressed: () {
                    if (isEditingUsername) {
                      updateUsername();
                    } else {
                      setState(() => isEditingUsername = true);
                    }
                  },
                ),
              ],
            ),

            Text(_user?.email ?? "No Email", style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text("Event Code: ${eventCode ?? 'N/A'}", style: TextStyle(fontSize: 16, color: Colors.grey)),

            SizedBox(height: 12),

            // Show assigned sub-events
            if (memberDetails != null && memberDetails!.containsKey("subEventCode"))
              Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("My Sub-Events", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ...(memberDetails!["subEventCode"] as List).map((code) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text(code.toString(), style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 10),
            Card(
              child: SwitchListTile(
                title: Text("Online Status", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(isOnline ? "You are visible to others" : "You are hidden from others"),
                value: isOnline,
                activeColor: Colors.green,
                onChanged: toggleOnlineStatus,
                secondary: Icon(
                  isOnline ? Icons.visibility : Icons.visibility_off,
                  color: isOnline ? Colors.green : Colors.grey,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text("Logout"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: _logout,
            ),
          ],
        ),
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
}

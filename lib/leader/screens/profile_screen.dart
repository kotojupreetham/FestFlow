import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'leader_dashboard.dart';
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
  Map<String, dynamic>? leaderDetails;
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
      // Read from leader/{email}/events
      QuerySnapshot eventSnapshot = await _firestore
          .collection("leader")
          .doc(_user!.email)
          .collection("events")
          .get();

      if (eventSnapshot.docs.isNotEmpty) {
        String fetchedEventCode = eventSnapshot.docs.first.id;
        setState(() => eventCode = fetchedEventCode);
        fetchLeaderDetails(fetchedEventCode);
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching event code: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchLeaderDetails(String code) async {
    try {
      // Read leader data from events/{code}.leader map field
      DocumentSnapshot eventDoc = await _firestore
          .collection("events")
          .doc(code)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;

        if (data.containsKey("leader") && data["leader"] != null) {
          Map<String, dynamic> leader = Map<String, dynamic>.from(data["leader"]);

          setState(() {
            leaderDetails = leader;
            _usernameController.text = leader["username"] ?? "No Name";
            isOnline = leader["isOnline"] ?? false;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching leader details: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> updateUsername() async {
    if (eventCode == null || _user == null) return;

    String newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;

    try {
      // Update in events/{eventCode}.leader map field
      await _firestore
          .collection("events")
          .doc(eventCode)
          .update({"leader.username": newUsername});

      // Also update in leader/{email}
      await _firestore.collection("leader").doc(_user!.email).update({
        "username": newUsername
      });

      setState(() {
        leaderDetails!["username"] = newUsername;
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
          .update({"leader.isOnline": value});
          
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
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  child: Text(
                    (leaderDetails?["username"] ?? "?")[0].toUpperCase(),
                    style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
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
                  leaderDetails?["username"] ?? "No Name",
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
              MaterialPageRoute(builder: (context) => LeaderDashboard()),
                  (route) => false,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'guest_dashboard.dart';
import '../../home/dashboard/home_page.dart';
//import 'package:image_picker/image_picker.dart';
import 'dart:io';
//import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _user;
  String? eventCode;
  String? username;
  Map<String, dynamic>? leaderDetails;
  bool isLoading = true;
  bool isEditingUsername = false;
  final TextEditingController _usernameController = TextEditingController();
  String? _profileImageUrl;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    fetchEventCode();
  }

  Future<void> fetchEventCode() async {
    _user = _auth.currentUser;
    if (_user == null || _user!.email == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.email).get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        username = data.containsKey('username') ? data['username'] : 'No Name';
      }

      QuerySnapshot eventSnapshot = await _firestore
          .collection("users")
          .doc(_user!.email)
          .collection("events")
          .get();

      if (eventSnapshot.docs.isNotEmpty) {
        String fetchedEventCode = eventSnapshot.docs.first.id; // Correct way to get the eventCode is usually the doc ID if mapped properly, but falling back to data if needed.
        Map<String, dynamic> eventData = eventSnapshot.docs.first.data() as Map<String, dynamic>;
        fetchedEventCode = eventData.containsKey('eventCode') ? eventData['eventCode'] : eventSnapshot.docs.first.id;

        setState(() => eventCode = fetchedEventCode);
        fetchGuestDetails(fetchedEventCode);
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching event code: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchGuestDetails(String code) async {
    if (_user == null || _user!.email == null) return;
    try {
      DocumentSnapshot guestDoc = await _firestore
          .collection("events")
          .doc(code)
          .collection("guest")
          .doc(_user!.email)
          .get();

      if (guestDoc.exists && guestDoc.data() != null) {
        Map<String, dynamic> data = guestDoc.data() as Map<String, dynamic>;

        setState(() {
          leaderDetails = data;
          _usernameController.text = data["username"] ?? username ?? "No Name";
          _profileImageUrl = data["profileImage"];
          isLoading = false;
        });
      } else {
        setState(() {
          _usernameController.text = username ?? "No Name";
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching guest details: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> updateUsername() async {
    if (eventCode == null || _user == null) return;

    String newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;

    try {
      if (eventCode != null && eventCode!.isNotEmpty) {
        await _firestore
            .collection("events")
            .doc(eventCode)
            .collection("guest")
            .doc(_user!.email)
            .update({"username": newUsername});
      }
      await _firestore.collection("users").doc(_user!.email).update({
        "username": newUsername
      });

      setState(() {
        if (leaderDetails != null) {
          leaderDetails!["username"] = newUsername;
        }
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

  /*Future<void> pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => isUploadingImage = true);
    File file = File(pickedFile.path);
    String filePath = "profile_images/${_user!.uid}.jpg";

    try {
      await _storage.ref(filePath).putFile(file);
      String downloadUrl = await _storage.ref(filePath).getDownloadURL();

      await _firestore.collection("users").doc(_user!.email).update({
        "profileImage": downloadUrl
      });

      if (eventCode != null && eventCode!.isNotEmpty) {
        await _firestore
            .collection("events")
            .doc(eventCode)
            .collection("guest")
            .doc(_user!.email)
            .update({
          "profileImage": downloadUrl,
        });
      }
      setState(() => _profileImageUrl = downloadUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile picture updated!")),
      );
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image.")),
      );
    } finally {
      setState(() => isUploadingImage = false);
    }
  }*/

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
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.edit, size: 18),
                      onPressed:(){} //pickAndUploadImage,
                    ),
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
                  username!,
                  //leaderDetails?["username"] ?? "No Name",
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
            MaterialPageRoute(builder: (context) => GuestDashboard()),
                (route) => false,
          );
        }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

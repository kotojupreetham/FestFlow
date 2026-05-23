
//member_page.dart
import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../leader_dashboard.dart';
import 'add_member.dart';
import 'manage_members.dart';
import 'search_members.dart';
import 'member_details.dart';

class MemberPage extends StatefulWidget {
  final String eventCode;

  const MemberPage({Key? key, required this.eventCode}) : super(key: key);

  @override
  _MemberPageState createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  bool isUserOnline = true;
  String? leaderId;

  List<Map<String, dynamic>> members = [];
  List<String> pendingInvites = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderId();
    fetchMembers();
  }

  Future<void> _fetchLeaderId() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        leaderId = currentUser.email;
      });

      // Update leader's online status in events/{eventCode}.leader map field
      await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .update({"leader.isOnline": isUserOnline});
    }
  }

  Future<void> fetchMembers() async {
    try {
      QuerySnapshot memberSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .get();

      DocumentSnapshot eventDoc = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .get();

      setState(() {
        members = memberSnapshot.docs
            .where((doc) => doc.id != "init") // Exclude init doc
            .map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data["id"] = doc.id; // doc.id = email
          data["isOnline"] = data.containsKey("isOnline") ? data["isOnline"] : false;
          return data;
        }).toList();

        // Safely handle pendingInvites (may not exist in new structure)
        if (eventDoc.exists && eventDoc.data() != null) {
          Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
          pendingInvites = List<String>.from(eventData["pendingInvites"] ?? []);
        }
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching members: $e");
      setState(() => isLoading = false);
    }
  }

  void _toggleLeaderStatus() async {
    setState(() {
      isUserOnline = !isUserOnline;
    });

    // Update leader online status in events/{eventCode}.leader map field
    await _firestore
        .collection("events")
        .doc(widget.eventCode)
        .update({"leader.isOnline": isUserOnline});
  }

  void _removePendingInvite(String email) async {
    try {
      DocumentReference eventRef = _firestore.collection("events").doc(widget.eventCode);
      await eventRef.update({
        "pendingInvites": FieldValue.arrayRemove([email])
      });

      setState(() {
        pendingInvites.remove(email);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Removed pending invite: $email")),
      );
    } catch (e) {
      print("Error removing pending invite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Members")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProfileIconWithStatus(),
                _buildIconWithText(Icons.add, "Add Member", Colors.green, AddMember(eventCode: widget.eventCode)),
                _buildIconWithText(Icons.settings, "Manage", Colors.orange, ManageMembers(eventCode: widget.eventCode)),
                _buildIconWithText(Icons.search, "Search", Colors.purple, SearchMembers(eventCode: widget.eventCode)),
              ],
            ),
          ),

          Divider(thickness: 3, color: Colors.black),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView(
              children: [
                ...members.map((member) => ListTile(
                  leading: _buildProfileImageWithStatus(member),
                  title: Text(member["username"] ?? member["email"] ?? "Unknown"),
                  subtitle: Text(member["email"] ?? "No email"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (member["isJoined"] != true)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Not Joined",
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberDetails(
                          eventCode: widget.eventCode,
                          memberId: member["id"],
                        ),
                      ),
                    );
                  },
                )),

                if (pendingInvites.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Pending Invites", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...pendingInvites.map((email) => ListTile(
                        leading: Icon(Icons.email, color: Colors.grey),
                        title: Text(email),
                        subtitle: Text("Invitation Sent"),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removePendingInvite(email),
                        ),
                      )),
                    ],
                  ),
              ],
            ),
          ),
        ],
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

  Widget _buildIconWithText(IconData icon, String text, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildProfileIconWithStatus() {
    return GestureDetector(
      onTap: _toggleLeaderStatus,
      child: Column(
        children: [
          Stack(
            children: [
              Icon(Icons.person, color: Colors.blue, size: 30),
              Positioned(
                bottom: 0,
                right: 0,
                child: _statusIndicator(isUserOnline),
              ),
            ],
          ),
          Text("Profile", style: TextStyle(color: Colors.blue)),
          Container(
            margin: EdgeInsets.only(top: 4),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isUserOnline ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isUserOnline ? "Online" : "Offline",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIndicator(bool isOnline) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildProfileImageWithStatus(Map<String, dynamic> member) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: member.containsKey("profilePic") && member["profilePic"] != null && member["profilePic"].isNotEmpty
              ? NetworkImage(member["profilePic"])
              : null,
          child: member.containsKey("profilePic") ? null : Icon(Icons.person, size: 24, color: Colors.grey[700]),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: _statusIndicator(member["isOnline"] ?? false),
        ),
      ],
    );
  }
}

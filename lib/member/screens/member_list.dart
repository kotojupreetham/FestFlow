import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'member_dashboard.dart';

class MemberList extends StatefulWidget {
  final String eventCode;

  const MemberList({Key? key, required this.eventCode}) : super(key: key);

  @override
  _MemberListState createState() => _MemberListState();
}

class _MemberListState extends State<MemberList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  String? currentUserId;
  Map<String, dynamic>? leaderData;
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        currentUserId = currentUser.uid;
      });
      fetchLeader();
      fetchMembers();
    }
  }

  Future<void> fetchLeader() async {
    try {
      // Fetch leader from the event document's leader map
      DocumentSnapshot eventDoc = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
        if (data.containsKey("leader") && data["leader"] != null) {
          setState(() {
            leaderData = Map<String, dynamic>.from(data["leader"]);
          });
        }
      }
    } catch (e) {
      print("Error fetching leader: $e");
    }
  }

  Future<void> fetchMembers() async {
    try {
      QuerySnapshot memberSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .get();

      setState(() {
        members = memberSnapshot.docs
            .where((doc) => doc.id != "init")
            .map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data["id"] = doc.id;
          return data;
        })
            .where((member) => member["id"] != currentUserId)
            .toList();

        isLoading = false;
      });
    } catch (e) {
      print("Error fetching members: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Members")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          if (leaderData != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Leader", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            _buildMemberTile(leaderData!),
            Divider(thickness: 2),
          ],
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Members", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...members.map((member) => _buildMemberTile(member)).toList(),
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

  Widget _buildMemberTile(Map<String, dynamic> member) {
    return ListTile(
      leading: _buildProfileImageWithStatus(member),
      title: Text(member["username"] ?? "Unknown"),
      subtitle: Text(member["email"] ?? "No email"),
    );
  }

  Widget _buildProfileImageWithStatus(Map<String, dynamic> member) {
    String name = member["username"] ?? "?";
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blue,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: _statusIndicator(member["isOnline"] ?? false),
        ),
      ],
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
}

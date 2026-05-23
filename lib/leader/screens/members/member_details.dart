
//member_details.dart

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'member_page.dart';

class MemberDetails extends StatefulWidget {
  final String eventCode;
  final String memberId;

  const MemberDetails({Key? key, required this.eventCode, required this.memberId}) : super(key: key);

  @override
  _MemberDetailsState createState() => _MemberDetailsState();
}

class _MemberDetailsState extends State<MemberDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  Map<String, dynamic>? memberData;
  List<String> subEventNames = [];

  @override
  void initState() {
    super.initState();
    fetchMemberDetails();
  }

  Future<void> fetchMemberDetails() async {
    try {
      // Fetch member details
      DocumentSnapshot memberSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .doc(widget.memberId)
          .get();

      // Fetch sub-events where the member is present
      QuerySnapshot subEventSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .get();

      if (memberSnapshot.exists && memberSnapshot.data() != null) {
        Map<String, dynamic> data = memberSnapshot.data() as Map<String, dynamic>;

        // Extract sub-event names where the member is listed
        List<String> subEvents = subEventSnapshot.docs
            .where((doc) => doc.id != "init") // Exclude init doc
            .where((doc) {
          Map<String, dynamic> subData = doc.data() as Map<String, dynamic>;
          if (!subData.containsKey("members")) return false; // Safety check
          List<dynamic>? members = subData["members"];
          return members != null && members.any((m) => m["id"] == widget.memberId || m["email"] == widget.memberId);
        })
            .map((doc) => doc["name"] as String)
            .toList();

        setState(() {
          memberData = data;
          subEventNames = subEvents;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Member Details")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: memberData?["profilePic"] != null && memberData?["profilePic"].isNotEmpty
                    ? NetworkImage(memberData!["profilePic"])
                    : null,
                child: memberData?["profilePic"] == null || memberData?["profilePic"].isEmpty
                    ? Icon(Icons.person, size: 50, color: Colors.grey[700])
                    : null,
              ),
            ),
            SizedBox(height: 12),

            // Member Name
            Center(
              child: Text(
                memberData?["username"] ?? "Unknown",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: 5),

            // Online/Offline Status
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: memberData?["isOnline"] == true ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  memberData?["isOnline"] == true ? "Online" : "Offline",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Email
            ListTile(
              leading: Icon(Icons.email, color: Colors.blue),
              title: Text("Email"),
              subtitle: Text(memberData?["email"] ?? "No email available"),
            ),

            Divider(),

            // Sub-Events List
            Text("Sub-Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            subEventNames.isNotEmpty
                ? Column(
              children: subEventNames.map((subEvent) {
                return ListTile(
                  leading: Icon(Icons.event, color: Colors.orange),
                  title: Text(subEvent),
                );
              }).toList(),
            )
                : Text("No events found", style: TextStyle(color: Colors.grey)),

            SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: customFloatingActionButton(onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MemberPage(eventCode: widget.eventCode)),
                (route) => false,
          );
        }),
    );
  }
}

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'member_event_details.dart';
import 'member_dashboard.dart';

class MemberEventPage extends StatefulWidget {
  final String eventCode;

  const MemberEventPage({Key? key, required this.eventCode}) : super(key: key);

  @override
  _MemberEventPageState createState() => _MemberEventPageState();
}

class _MemberEventPageState extends State<MemberEventPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  String? memberId;
  List<String> subEventCodes = [];
  List<Map<String, dynamic>> subEvents = [];

  @override
  void initState() {
    super.initState();
    fetchMemberSubEvents();
  }

  Future<void> fetchMemberSubEvents() async {
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    memberId = user.email!;
    List<Map<String, dynamic>> allSubEvents = [];

    try {
      // Step 1: Fetch all sub-events from Firestore
      QuerySnapshot subEventsSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .get();

      allSubEvents = subEventsSnapshot.docs
          .where((doc) => doc.id != "init")
          .map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data["subEventCode"] = doc.id;
        return data;
      }).toList();

      // Step 2: Fetch sub-event codes assigned to the member
      DocumentSnapshot memberDoc = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .doc(memberId)
          .get();

      if (memberDoc.exists && memberDoc.data() != null) {
        Map<String, dynamic> data = memberDoc.data() as Map<String, dynamic>;

        if (data.containsKey("subEventCode") && data["subEventCode"] is List) {
          subEventCodes = List<String>.from(data["subEventCode"]);
        }
      }

      // Step 3: Separate assigned & unassigned sub-events
      List<Map<String, dynamic>> assignedEvents = [];
      List<Map<String, dynamic>> unassignedEvents = [];

      for (var event in allSubEvents) {
        if (subEventCodes.contains(event["subEventCode"])) {
          assignedEvents.add(event);
        } else {
          unassignedEvents.add(event);
        }
      }

      // Step 4: Update state with both lists
      setState(() {
        subEvents = assignedEvents; // Assigned events
        subEvents.addAll(unassignedEvents); // Append unassigned events below
        isLoading = false;
      });

    } catch (e) {
      print("Error fetching events: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchSubEventDetails() async {
    List<Map<String, dynamic>> fetchedEvents = [];

    for (String subEventCode in subEventCodes) {
      DocumentSnapshot subEventDoc = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .doc(subEventCode)
          .get();
      print("done");
      if (subEventDoc.exists && subEventDoc.data() != null) {
        print("done");
        Map<String, dynamic> data = subEventDoc.data() as Map<String, dynamic>;
        data["subEventCode"] = subEventCode;
        fetchedEvents.add(data);
      }
    }

    setState(() {
      subEvents = fetchedEvents;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sub-Events")),
      body: Column(
        children: [
          Divider(thickness: 3, color: Colors.black),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : subEvents.isEmpty
                ? Center(child: Text("No sub-events available."))
                : ListView.builder(
              itemCount: subEvents.length,
              itemBuilder: (context, index) {
                final subEvent = subEvents[index];
                bool isAssigned = subEventCodes.contains(subEvent["subEventCode"]); // Check assignment

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAssigned ? Colors.green : Colors.grey[300],
                      child: Icon(Icons.event, color: isAssigned ? Colors.white : Colors.grey[600]),
                    ),
                    title: Text(subEvent["name"] ?? "Unnamed Sub-Event", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      isAssigned ? (subEvent["type"] ?? "Tap to fill details") : "Not assigned to you",
                      style: TextStyle(color: isAssigned ? Colors.black54 : Colors.grey),
                    ),
                    trailing: isAssigned ? Icon(Icons.arrow_forward_ios, size: 16) : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemberEventDetails(
                            eventCode: widget.eventCode,
                            subEventCode: subEvent["subEventCode"],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
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
}

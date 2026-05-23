import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'guest_sub_event_details.dart';
import 'guest_dashboard.dart';

class GuestEventDetails extends StatefulWidget {
  final String eventCode;

  const GuestEventDetails({Key? key, required this.eventCode}) : super(key: key);

  @override
  _GuestEventDetailsState createState() => _GuestEventDetailsState();
}

class _GuestEventDetailsState extends State<GuestEventDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? eventData;
  List<Map<String, dynamic>> subEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEventDetails();
  }

  Future<void> fetchEventDetails() async {
    try {
      // Fetch main event details
      DocumentSnapshot eventDoc = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .get();

      print("Fetched EventDoc: $eventDoc");

      if (eventDoc.exists && eventDoc.data() != null) {
        Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
        print("Fetched Event Data: $data");

        if (data.containsKey("details") && data["details"] != null) {
          setState(() {
            eventData = Map<String, dynamic>.from(data["details"]);
          });
        }
      }

      // Fetch sub-events
      QuerySnapshot subEventSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .orderBy("createdAt", descending: true) // Order by creation time
          .get();

      print("Sub-Event Query Snapshot: $subEventSnapshot");
      print("Number of sub-events found: ${subEventSnapshot.docs.length}");

      if (subEventSnapshot.docs.isNotEmpty) {
        setState(() {
          subEvents = subEventSnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            print("Fetched Sub-Event: $data");
            return {
              "id": doc.id,
              "name": data["name"] ?? "Unnamed Sub-Event",
              "description": data["description"] ?? "No description",
            };
          }).toList();
        });
      } else {
        print("No sub-events found.");
      }

      setState(() => isLoading = false);
    } catch (e) {
      print("Error fetching event details: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Event Details")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : eventData == null
          ? Center(child: Text("Event not found"))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // **Main Event Details**
            Text("Main Event: ${eventData!["title"] ?? "Unnamed Event"}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Description: ${eventData!["description"] ?? "No description"}"),
            SizedBox(height: 20),

            // **Sub-events Section**
            Text("Sub-Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(thickness: 2),
            subEvents.isEmpty
                ? Text("No sub-events available")
                : Column(
              children: subEvents.map((subEvent) {
                return ListTile(
                  leading: Icon(Icons.event_note),
                  title: Text(subEvent["name"]),
                  subtitle: Text(subEvent["description"]),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuestSubEventDetails(
                          eventCode: widget.eventCode,
                          subEventCode: subEvent["id"],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
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

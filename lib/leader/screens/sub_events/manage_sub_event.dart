
//manager_event.dart
import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sub_event_page.dart';
import 'edit_sub_event.dart';

class ManageSubEvent extends StatefulWidget {
  final String eventCode; // Parent event code to fetch sub-events

  const ManageSubEvent({Key? key, required this.eventCode}) : super(key: key);

  @override
  _ManageSubEventState createState() => _ManageSubEventState();
}

class _ManageSubEventState extends State<ManageSubEvent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isManaging = false; // Toggle delete mode
  List<Map<String, dynamic>> subEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSubEvents();
  }

  Future<void> fetchSubEvents() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .orderBy("createdAt", descending: false)
          .get();

      setState(() {
        subEvents = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data["id"] = doc.id; // Store Firestore document ID
          return data;
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching sub-events: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteEvent(String subEventId) async {
    try {
      await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .doc(subEventId)
          .delete();

      setState(() {
        subEvents.removeWhere((event) => event["id"] == subEventId);
      });

      QuerySnapshot memberSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode).collection("member").get();

      for (var doc in memberSnapshot.docs) {
        String memberId = doc.id;
        List<dynamic>? subEventCodes = doc["subEventCode"];

        if (subEventCodes != null && subEventCodes.contains(subEventId)) {
          await _firestore.collection("events").doc(widget.eventCode).collection("member").doc(memberId).update({
            "subEventCode": FieldValue.arrayRemove([subEventId])
          });
        }
      }


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Event deleted successfully!")),
      );
    } catch (e) {
      print("Error deleting event: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete event.")),
      );
    }
  }

  void _confirmDelete(String subEventId, String eventName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text("Are you sure you want to remove '$eventName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              deleteEvent(subEventId);
              Navigator.pop(context);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Sub-Events")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isManaging = !isManaging;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isManaging ? Colors.red : Colors.orange,
                  ),
                  child: Text(isManaging ? "Cancel" : "Enable Delete"),
                ),
              ],
            ),
          ),
          Divider(thickness: 2, color: Colors.black),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : subEvents.isEmpty
                ? Center(child: Text("No sub-events available"))
                : ListView.builder(
              itemCount: subEvents.length,
              itemBuilder: (context, index) {
                final subEvent = subEvents[index];
                return ListTile(
                  leading: Icon(Icons.event),
                  title: Text(subEvent["name"] ?? "Unnamed Event"),
                  trailing: isManaging 
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditSubEvent(
                                      eventCode: widget.eventCode,
                                      subEventData: subEvent,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(subEvent["id"], subEvent["name"]),
                            ),
                          ],
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: customFloatingActionButton(onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SubEventPage(eventCode: widget.eventCode)),
                  (route) => false,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

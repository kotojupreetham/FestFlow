import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:festflow/theme/button/floating_Action_Button.dart';
import '../widgets/stats_widget.dart';
import '../widgets/floating_menu.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'settings/settings_page.dart';
import '../../global.dart';

class GuestDashboard extends StatefulWidget {
  @override
  _GuestDashboardState createState() => _GuestDashboardState();
}

class _GuestDashboardState extends State<GuestDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _menuOpen = false;
  String? eventCode;
  Map<String, dynamic>? eventDetails;
  bool isLoading = true;
  int subEventCount = 0;
  User? _user;

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

    if (GlobalState.activeEventCode != null) {
      setState(() {
        eventCode = GlobalState.activeEventCode;
      });
      fetchEventDetails(GlobalState.activeEventCode!);
    } else {
      // Fallback: try to pull eventCode from Firestore user doc
      if (_user != null && _user!.email != null) {
        try {
          QuerySnapshot eventSnapshot = await _firestore
              .collection('users')
              .doc(_user!.email)
              .collection('events')
              .get();

          if (eventSnapshot.docs.isNotEmpty) {
            Map<String, dynamic> data =
                eventSnapshot.docs.first.data() as Map<String, dynamic>;
            String fallbackCode = data.containsKey('eventCode')
                ? data['eventCode']
                : eventSnapshot.docs.first.id;
            GlobalState.activeEventCode = fallbackCode;
            setState(() {
              eventCode = fallbackCode;
            });
            fetchEventDetails(fallbackCode);
          } else {
            setState(() => isLoading = false);
          }
        } catch (e) {
          print("Error fetching fallback event code: $e");
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> fetchEventDetails(String code) async {
    try {
      DocumentSnapshot eventDoc =
          await _firestore.collection("events").doc(code).get();

      if (eventDoc.exists && eventDoc.data() != null) {
        Map<String, dynamic> data =
            eventDoc.data() as Map<String, dynamic>;

        if (data.containsKey("details") && data["details"] != null) {
          Map<String, dynamic> firstEvent =
              Map<String, dynamic>.from(data["details"]);

          // Fetch Sub-Events Count
          QuerySnapshot subEventSnapshot = await _firestore
              .collection("events")
              .doc(code)
              .collection("sub-events")
              .get();

          int fetchedSubEvents =
              subEventSnapshot.docs.where((doc) => doc.id != "init").length;

          setState(() {
            eventDetails = firstEvent;
            subEventCount = fetchedSubEvents;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching event details: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guest Dashboard"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // **Event Details**
                eventDetails == null
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event Image with Title
                          eventDetails!['image'] != null &&
                                  eventDetails!['image'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    eventDetails!['image'],
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey[700]),
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.image,
                                      size: 50, color: Colors.grey[700]),
                                ),
                          SizedBox(height: 10),
                          Text(
                            eventDetails!['title'] ?? "Event Name",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),

                          // Event Details (Dynamically Displayed)
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: eventDetails!.entries
                                    .where((entry) => ![
                                          "createdBy",
                                          "createdByID",
                                          "isApproved",
                                          "timestamp",
                                          "image"
                                        ].contains(entry.key))
                                    .map((entry) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Text(
                                            "${entry.key}: ${entry.value}",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: 20),

                // **Stats Widget (Sub-Events count)**
                StatsWidget(
                  totalAttendees: 1,
                  totalEvents: subEventCount,
                ),
                SizedBox(height: 20),
              ],
            ),
          ),

          // **Floating Menu**
          FloatingMenu(
            isOpen: _menuOpen,
            eventCode: eventCode ?? "",
            onClose: () {
              setState(() {
                _menuOpen = false;
              });
            },
          ),
        ],
      ),

      // **Floating Action Button (FAB)**
      floatingActionButton: customFloatingActionButton(
        icon: _menuOpen ? Icons.close : Icons.add,
        onPressed: () {
          setState(() {
            _menuOpen = !_menuOpen;
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

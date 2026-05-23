import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:festflow/theme/button/floating_Action_Button.dart';
import '../widgets/stats_widget.dart';
import '../widgets/floating_menu.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'settings/settings_page.dart';
import 'edit_event.dart'; // Import Edit Event Screen
import 'package:festflow/global.dart';
import '../../widgets/qr_viewer_dialog.dart';

class LeaderDashboard extends StatefulWidget {
  @override
  _LeaderDashboardState createState() => _LeaderDashboardState();
}

class _LeaderDashboardState extends State<LeaderDashboard> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _menuOpen = false;
  String? eventCode;
  bool isOnline = false;
  Map<String, dynamic>? eventDetails;
  bool isLoading = true;
  User? _user;

  // Dynamic stats
  int totalSubEvents = 0;
  int totalMembers = 0;
  int totalGuests = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchEventCode();
    _setOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _setOnlineStatus(false);
    }
  }

  Future<void> _setOnlineStatus(bool onlineStatus) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      try {
        await _firestore.collection('users').doc(currentUser.email).set({
          'isOnline': onlineStatus,
        }, SetOptions(merge: true));

        if (GlobalState.activeEventCode != null && GlobalState.activeEventCode!.isNotEmpty) {
          await _firestore
              .collection('events')
              .doc(GlobalState.activeEventCode)
              .collection('leader')
              .doc(currentUser.email)
              .set({'isOnline': onlineStatus}, SetOptions(merge: true));
        }

        if (mounted) {
          setState(() {
            isOnline = onlineStatus;
          });
        }
      } catch (e) {
        print("Error updating online status: $e");
      }
    }
  }

  Future<void> fetchEventCode() async {
    _user = _auth.currentUser;
    if (_user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      if (GlobalState.activeEventCode != null && GlobalState.activeEventCode!.isNotEmpty) {
        String fetchedEventCode = GlobalState.activeEventCode!;

        setState(() {
          eventCode = fetchedEventCode;
        });

        fetchEventDetails(fetchedEventCode);
        fetchStats();
      } else {
        // Fallback: try to pull eventCode from Firestore user doc
        if (_user != null && _user!.email != null) {
          QuerySnapshot eventSnapshot = await _firestore
              .collection('users')
              .doc(_user!.email)
              .collection('events')
              .get();

          if (eventSnapshot.docs.isNotEmpty) {
            Map<String, dynamic> data = eventSnapshot.docs.first.data() as Map<String, dynamic>;
            String fallbackCode = data.containsKey('eventCode') ? data['eventCode'] : eventSnapshot.docs.first.id;
            GlobalState.activeEventCode = fallbackCode;
            setState(() {
              eventCode = fallbackCode;
            });
            fetchEventDetails(fallbackCode);
            fetchStats();
          } else {
            setState(() => isLoading = false);
          }
        } else {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      print("Error loading active event code: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchEventDetails(String code) async {
    try {
      // Read details from events/{eventCode} map field
      DocumentSnapshot eventDoc = await _firestore
          .collection("events")
          .doc(code)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;

        // details is a map field on the document
        if (data.containsKey("details") && data["details"] != null) {
          Map<String, dynamic> details = Map<String, dynamic>.from(data["details"]);

          setState(() {
            eventDetails = details;
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

  Future<void> fetchStats() async {
    if (_user == null || eventCode == null) return;

    try {
      // Count sub-events
      QuerySnapshot subEventSnapshot = await _firestore
          .collection("events")
          .doc(eventCode)
          .collection("sub-events")
          .get();

      // Count joined members (exclude "init" doc)
      QuerySnapshot memberSnapshot = await _firestore
          .collection("events")
          .doc(eventCode)
          .collection("member")
          .get();
      int members = memberSnapshot.docs
          .where((doc) => doc.id != "init" && doc.data() != null)
          .where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return data["isJoined"] == true;
          })
          .length;

      // Count guests (exclude "init" doc)
      QuerySnapshot guestSnapshot = await _firestore
          .collection("events")
          .doc(eventCode)
          .collection("guest")
          .get();
      int guests = guestSnapshot.docs
          .where((doc) => doc.id != "init")
          .length;

      setState(() {
        totalSubEvents = subEventSnapshot.docs.where((doc) => doc.id != "init").length;
        totalMembers = members;
        totalGuests = guests;
      });
    } catch (e) {
      print("Error fetching stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leader Dashboard"),
        actions: [
          if (eventDetails != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 6,
                      backgroundColor: isOnline ? Colors.green : Colors.grey,
                    ),
                    SizedBox(width: 4),
                    Text(
                      isOnline ? "Online" : "Offline",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          if (eventCode != null)
            IconButton(
              icon: const Icon(Icons.qr_code_2, size: 28),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => QRViewerDialog(eventCode: eventCode!),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings, size: 28),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
                    (route) => false,
              );
            },
          ),
        ],
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
                    eventDetails!['image'] != null && eventDetails!['image'].isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        eventDetails!['image'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey[700]),
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
                      child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 10),
                    Text(
                      eventDetails!['title'] ?? "Event Name",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),

                    // Event Details (Dynamically Displayed)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: eventDetails!.entries
                              .where((entry) =>
                          !["createdBy", "createdByID", "isApproved","image", "timestamp"]
                              .contains(entry.key)) // Exclude restricted fields
                              .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              "${entry.key}: ${entry.value}",
                              style: TextStyle(fontSize: 16),
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                    ),

                    // Edit Event Button
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.edit),
                      label: Text("Edit Event"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditEventScreen(eventId: eventDetails!['eventCode']),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // **Stats Widget**
                StatsWidget(
                  totalAttendees: totalGuests,
                  totalEvents: totalSubEvents,
                  totalMembers: totalMembers,
                ),
                SizedBox(height: 20),
              ],
            ),
          ),

          // **Floating Menu**
          FloatingMenu(
            isOpen: _menuOpen,
            eventCode: eventDetails?['eventCode'] ?? "", // Use safe null check
            onClose: () {
              setState(() {
                _menuOpen = false;
              });
            },
          ),
        ],
      ),

      // **Bottom Navigation Bar**
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.person, size: 28),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
            SizedBox(width: 50), // Spacer for Floating Button
            IconButton(
              icon: const Icon(Icons.notifications, size: 28),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen(eventCode: eventCode!)),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: customFloatingActionButton(
        icon: _menuOpen ? Icons.close : Icons.add,
        onPressed: () {
          setState(() {
            _menuOpen = !_menuOpen;
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

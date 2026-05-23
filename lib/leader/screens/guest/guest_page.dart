// guest_page.dart
// Hub page for Guest management (similar to sub_event_page.dart).
// Provides navigation to: Manage Questions, Approve Guests.
//
// TODO: Check if current user has guest management permission (for future member access)
// TODO: When member delegation is implemented, this page should be accessible
//       from the member's floating menu if the leader grants permission.

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../leader_dashboard.dart';
import 'guest_questions_page.dart';
import 'approve_guest_page.dart';

class GuestPage extends StatefulWidget {
  final String eventCode;

  const GuestPage({Key? key, required this.eventCode}) : super(key: key);

  @override
  _GuestPageState createState() => _GuestPageState();
}

class _GuestPageState extends State<GuestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Guest Management"),
      ),
      body: Column(
        children: [
          // Icon row (same pattern as SubEventPage)
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIconWithText(
                  Icons.quiz,
                  "Manage Questions",
                  Colors.blue,
                  GuestQuestionsPage(eventCode: widget.eventCode),
                ),
                _buildIconWithText(
                  Icons.how_to_reg,
                  "Approve Guests",
                  Colors.green,
                  ApproveGuestPage(eventCode: widget.eventCode),
                ),
                // TODO: Future - Add "Search Guests" icon here
                _buildIconWithText(
                  Icons.search,
                  "Search Guests",
                  Colors.orange,
                  null, // Placeholder for future search functionality
                ),
              ],
            ),
          ),

          Divider(thickness: 3, color: Colors.black),

          // Guest list with approval status
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("events")
                  .doc(widget.eventCode)
                  .collection("permissions")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No guest requests yet",
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    bool isApproved = data["isApproved"] ?? false;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isApproved ? Colors.green : Colors.orange,
                          child: Icon(
                            isApproved ? Icons.check : Icons.hourglass_empty,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(data["username"] ?? "Unknown User"),
                        subtitle: Text(data["email"] ?? doc.id),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isApproved ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isApproved ? "Approved" : "Pending",
                            style: TextStyle(
                              color: isApproved ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
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

  Widget _buildIconWithText(IconData icon, String text, Color color, Widget? page) {
    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Coming soon!")),
          );
        }
      },
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

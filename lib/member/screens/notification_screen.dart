
//notification_screen.dart (Member Side)

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'member_dashboard.dart';

class MemberNotificationScreen extends StatefulWidget {
  final String eventCode;

  const MemberNotificationScreen({Key? key, required this.eventCode}) : super(key: key);

  @override
  _MemberNotificationScreenState createState() => _MemberNotificationScreenState();
}

class _MemberNotificationScreenState extends State<MemberNotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("events")
            .doc(widget.eventCode)
            .collection("notifications")
            .orderBy("createdAt", descending: true)
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
                  Icon(Icons.notifications_off, size: 60, color: Colors.grey[400]),
                  SizedBox(height: 12),
                  Text("No notifications yet.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;

          // Filter: only show notifications targeted at "Everyone" or "Members"
          var filteredDocs = docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String target = data["target"] ?? "Everyone";
            return target == "Everyone" || target == "Members";
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Text("No notifications for you.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            );
          }

          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              var notif = filteredDocs[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Icon(Icons.notifications, color: Colors.blue),
                  title: Text(notif["title"] ?? "Untitled", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notif["message"] ?? ""),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ),
              );
            },
          );
        },
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

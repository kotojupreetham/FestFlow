
//notification_screen.dart

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'guest_dashboard.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Notifications")),
        body: Center(child: Text("Please log in to view notifications.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error fetching notifications."));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No notifications yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          var notificationDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notificationDocs.length,
            itemBuilder: (context, index) {
              var noteData = notificationDocs[index].data() as Map<String, dynamic>;
              String title = noteData['title'] ?? "Notification";
              String subtitle = noteData['subtitle'] ?? "You have a new update.";

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Icon(Icons.notifications, color: Colors.blue),
                  title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(subtitle),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: customFloatingActionButton(onPressed: () {
          // Navigate back to LeaderDashboard and remove history
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => GuestDashboard()),
            (route) => false, // Remove all previous routes
          );
        }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

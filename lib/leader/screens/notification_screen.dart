
//notification_screen.dart

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'leader_dashboard.dart';

class NotificationScreen extends StatefulWidget {
  final String eventCode;

  const NotificationScreen({Key? key, required this.eventCode}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        actions: [
          IconButton(
            icon: Icon(Icons.add_alert),
            tooltip: "Create Announcement",
            onPressed: () => _showCreateAnnouncementDialog(),
          ),
        ],
      ),
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
                  Text("No announcements yet.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  SizedBox(height: 8),
                  Text("Tap the bell icon to create one.", style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var notif = docs[index].data() as Map<String, dynamic>;
              String target = notif["target"] ?? "Everyone";
              IconData targetIcon = target == "Members"
                  ? Icons.people
                  : target == "Guests"
                      ? Icons.person_outline
                      : Icons.public;

              return Dismissible(
                key: Key(docs[index].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  _firestore
                      .collection("events")
                      .doc(widget.eventCode)
                      .collection("notifications")
                      .doc(docs[index].id)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Notification deleted")),
                  );
                },
                child: Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(targetIcon, color: Colors.blue),
                    title: Text(notif["title"] ?? "Untitled", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(notif["message"] ?? ""),
                        SizedBox(height: 4),
                        Text(
                          "To: $target",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
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

  void _showCreateAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String targetAudience = "Everyone";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Create Announcement"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Title",
                        hintText: "e.g. Schedule Updated",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        labelText: "Message",
                        hintText: "e.g. The event starts 30 mins earlier.",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: targetAudience,
                      decoration: InputDecoration(
                        labelText: "Send To",
                        border: OutlineInputBorder(),
                      ),
                      items: ["Everyone", "Members", "Guests"]
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() => targetAudience = val!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Title is required.")),
                      );
                      return;
                    }

                    await _firestore
                        .collection("events")
                        .doc(widget.eventCode)
                        .collection("notifications")
                        .add({
                      "title": titleController.text.trim(),
                      "message": messageController.text.trim(),
                      "target": targetAudience,
                      "senderEmail": _auth.currentUser?.email ?? "unknown",
                      "createdAt": FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Announcement sent to $targetAudience!")),
                    );
                  },
                  child: Text("Send"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

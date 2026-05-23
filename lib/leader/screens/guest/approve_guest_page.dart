// approve_guest_page.dart
// Displays pending and approved guests with their questionnaire answers.
// Leader can review answers and approve/revoke guest access.
//
// TODO: Check if current user has guest management permission (for future member access)

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../leader_dashboard.dart';

class ApproveGuestPage extends StatefulWidget {
  final String eventCode;

  ApproveGuestPage({required this.eventCode});

  @override
  _ApproveGuestPageState createState() => _ApproveGuestPageState();
}

class _ApproveGuestPageState extends State<ApproveGuestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Toggle guest approval and sync across collections
  Future<void> toggleApproval(String guestEmail, bool isApproved, Map<String, dynamic> data) async {
    try {
      bool newStatus = !isApproved;

      // 1. Toggle approval status in permissions
      await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("permissions")
          .doc(guestEmail)
          .update({"isApproved": newStatus});

      // 2. Add or remove from official guest list
      if (newStatus) {
        await _firestore
            .collection("events")
            .doc(widget.eventCode)
            .collection("guest")
            .doc(guestEmail)
            .set({
          "email": guestEmail,
          "username": data["username"] ?? "Unknown",
          "joinedAt": FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore
            .collection("events")
            .doc(widget.eventCode)
            .collection("guest")
            .doc(guestEmail)
            .delete();
      }

      // 3. Update the user's specific multi-event tracker
      await _firestore
          .collection("users")
          .doc(guestEmail)
          .collection("events")
          .doc(widget.eventCode)
          .update({"isApproved": newStatus}).catchError((e) {
        // If document doesn't exist yet, set it
        _firestore
            .collection("users")
            .doc(guestEmail)
            .collection("events")
            .doc(widget.eventCode)
            .set({
          "role": "guest",
          "eventCode": widget.eventCode,
          "isApproved": newStatus,
          "joinedAt": FieldValue.serverTimestamp(),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isApproved ? "Approval revoked!" : "Guest approved!")),
      );
    } catch (e) {
      print("Error updating approval: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update approval status.")));
    }
  }

  /// Show a detail dialog with the guest's answers to the questionnaire
  void _showGuestDetails(String guestEmail, Map<String, dynamic> data) async {
    bool isApproved = data["isApproved"] ?? false;
    Map<String, dynamic> answers = {};
    if (data.containsKey("answers") && data["answers"] != null) {
      answers = Map<String, dynamic>.from(data["answers"]);
    }

    // Fetch questions to display alongside answers
    List<DocumentSnapshot> questionDocs = [];
    try {
      QuerySnapshot questionsSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("guestQuestions")
          .orderBy("order")
          .get();
      questionDocs = questionsSnapshot.docs;
    } catch (e) {
      print("Error fetching questions: $e");
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: isApproved ? Colors.green : Colors.orange,
                child: Icon(
                  isApproved ? Icons.check : Icons.hourglass_empty,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data["username"] ?? "Unknown", style: TextStyle(fontSize: 16)),
                    Text(
                      data["email"] ?? guestEmail,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (questionDocs.isEmpty && answers.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "No questionnaire was submitted.",
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    )
                  else ...[
                    Text(
                      "Questionnaire Responses",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    ...questionDocs.map((qDoc) {
                      Map<String, dynamic> qData = qDoc.data() as Map<String, dynamic>;
                      String questionText = qData["question"] ?? "Unknown Question";
                      bool isRequired = qData["isRequired"] ?? false;
                      dynamic answer = answers[qDoc.id];

                      // Format answer for display
                      String displayAnswer;
                      if (answer == null || (answer is String && answer.isEmpty)) {
                        displayAnswer = "— No answer —";
                      } else if (answer is List) {
                        displayAnswer = answer.join(", ");
                      } else {
                        displayAnswer = answer.toString();
                      }

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    questionText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (isRequired)
                                  Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                displayAnswer,
                                style: TextStyle(
                                  color: answer == null ? Colors.grey : Colors.black87,
                                  fontStyle: answer == null ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isApproved ? Colors.red : Colors.green,
              ),
              onPressed: () {
                toggleApproval(guestEmail, isApproved, data);
                Navigator.pop(context);
              },
              child: Text(isApproved ? "Revoke" : "Approve"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Approve Guests")),
      body: StreamBuilder<QuerySnapshot>(
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
            return Center(child: Text("No guest requests available."));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              bool isApproved = data["isApproved"] ?? false;
              bool hasAnswers = data.containsKey("answers") && data["answers"] != null;

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
                  subtitle: Row(
                    children: [
                      Text(data["email"] ?? "No Email"),
                      if (hasAnswers) ...[
                        SizedBox(width: 8),
                        Icon(Icons.assignment_turned_in, size: 14, color: Colors.blue),
                      ],
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isApproved ? Colors.red : Colors.green,
                    ),
                    onPressed: () => toggleApproval(doc.id, isApproved, data),
                    child: Text(isApproved ? "Revoke" : "Approve"),
                  ),
                  // Tap to view details and answers
                  onTap: () => _showGuestDetails(doc.id, data),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: customFloatingActionButton(onPressed: () {
        Navigator.pop(context);
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

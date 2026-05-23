import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../guest/screens/guest_dashboard.dart';
import '../../global.dart';

class AboutEventDetailsPage extends StatefulWidget {
  final Map<String, dynamic> eventData;

  AboutEventDetailsPage({required this.eventData});

  @override
  _AboutEventDetailsPageState createState() => _AboutEventDetailsPageState();
}

class _AboutEventDetailsPageState extends State<AboutEventDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool requestSent = false;
  String? _username;
  String? _email;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    if (_user == null || _user!.email == null) return;
    try {
      DocumentSnapshot permDoc = await _firestore
          .collection("events")
          .doc(widget.eventData["id"])
          .collection("permissions")
          .doc(_user!.email)
          .get();

      if (permDoc.exists) {
        Map<String, dynamic> data = permDoc.data() as Map<String, dynamic>;
        setState(() {
          requestSent = true;
          if (data["isApproved"] == true) {
             widget.eventData["isApproved"] = true; // Use this as a flag
          }
        });
      }
    } catch (e) {
      print("Check reg status error: $e");
    }
  }

  Future<void> registerForEvent() async {
    if (_user == null || _user!.email == null) return;

    String eventCode = widget.eventData["id"];
    bool isPublic = widget.eventData["type"] == "Public";
    String email = _user!.email!;

    // Using email instead of uid for consistency
    DocumentReference userDoc = _firestore.collection("users").doc(email);
    DocumentReference permissionDoc =
        _firestore.collection("events").doc(eventCode).collection("permissions").doc(email);
    
    DocumentSnapshot userSnapshot = await userDoc.get();

    _username = (userSnapshot.data() as Map<String, dynamic>)["username"] ?? "Unknown";
    _email = email;

    if (isPublic) {
      // Directly register for public events
      await permissionDoc.set({
        "isRegistered": true, 
        "isApproved": true,
        "username": _username, 
        "email": _email
      });
      
      // Add to official guest list
      await _firestore.collection("events").doc(eventCode).collection("guest").doc(email).set({
        "email": _email,
        "username": _username,
        "uid": _user!.uid,
        "joinedAt": FieldValue.serverTimestamp(),
      });

      // Update multi-event structure for guest
      await userDoc.collection("events").doc(eventCode).set({
        "role": "guest",
        "isApproved": true,
        "eventCode": eventCode,
        "joinedAt": FieldValue.serverTimestamp(),
      });
      
      GlobalState.activeEventCode = eventCode;

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => GuestDashboard()),
            (route) => false,
      );
    } else {
      // Send join request for private events
      DocumentSnapshot permissionSnapshot = await permissionDoc.get();

      if (permissionSnapshot.exists && (permissionSnapshot.data() as Map<String, dynamic>)["isApproved"] == true) {
        // Already approved
        GlobalState.activeEventCode = eventCode;
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => GuestDashboard()),
              (route) => false,
        );
        return;
      }

      // Check if there are custom questions for this event
      QuerySnapshot questionsSnapshot = await _firestore
          .collection("events")
          .doc(eventCode)
          .collection("guestQuestions")
          .orderBy("order")
          .get();

      Map<String, dynamic> answers = {};

      if (questionsSnapshot.docs.isNotEmpty) {
        // Show questionnaire dialog and wait for result
        Map<String, dynamic>? result = await _showQuestionnaireDialog(questionsSnapshot.docs);
        if (result == null) {
          // User cancelled — don't submit
          return;
        }
        answers = result;
      }

      // Request pending
      await permissionDoc.set({
        "isRegistered": true,
        "isApproved": false,
        "username": _username,
        "email": _email,
        "answers": answers.isNotEmpty ? answers : null,
      });

      // Update multi-event structure for guest (pending)
      await userDoc.collection("events").doc(eventCode).set({
        "role": "guest",
        "isApproved": false,
        "eventCode": eventCode,
        "joinedAt": FieldValue.serverTimestamp(),
      });

      setState(() => requestSent = true);
    }
  }

  /// Show Google Forms-style questionnaire dialog
  /// Returns a map of {questionId: answer} or null if cancelled.
  Future<Map<String, dynamic>?> _showQuestionnaireDialog(List<DocumentSnapshot> questionDocs) async {
    // Controllers/state for each answer
    Map<String, dynamic> answers = {};
    Map<String, TextEditingController> textControllers = {};
    Map<String, List<String>> checkboxSelections = {};

    // Initialize controllers
    for (var doc in questionDocs) {
      Map<String, dynamic> qData = doc.data() as Map<String, dynamic>;
      String type = qData['type'] ?? 'short_answer';

      if (type == 'short_answer' || type == 'paragraph') {
        textControllers[doc.id] = TextEditingController();
      } else if (type == 'checkbox') {
        checkboxSelections[doc.id] = [];
      }
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Join Request Form"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Please answer the following questions to request access.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      SizedBox(height: 16),
                      ...questionDocs.map((doc) {
                        Map<String, dynamic> qData = doc.data() as Map<String, dynamic>;
                        String questionText = qData['question'] ?? '';
                        String type = qData['type'] ?? 'short_answer';
                        bool isRequired = qData['isRequired'] ?? false;
                        List<String> options = qData['options'] != null
                            ? List<String>.from(qData['options'])
                            : [];

                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question label
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      questionText,
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  if (isRequired)
                                    Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              SizedBox(height: 8),

                              // Answer widget based on type
                              if (type == 'short_answer')
                                TextField(
                                  controller: textControllers[doc.id],
                                  decoration: InputDecoration(
                                    hintText: 'Your answer',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                )
                              else if (type == 'paragraph')
                                TextField(
                                  controller: textControllers[doc.id],
                                  decoration: InputDecoration(
                                    hintText: 'Your answer',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  maxLines: 3,
                                )
                              else if (type == 'multiple_choice')
                                ...options.map((opt) => RadioListTile<String>(
                                      title: Text(opt),
                                      value: opt,
                                      groupValue: answers[doc.id] as String?,
                                      onChanged: (val) {
                                        setDialogState(() => answers[doc.id] = val);
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ))
                              else if (type == 'checkbox')
                                ...options.map((opt) => CheckboxListTile(
                                      title: Text(opt),
                                      value: checkboxSelections[doc.id]?.contains(opt) ?? false,
                                      onChanged: (val) {
                                        setDialogState(() {
                                          if (val == true) {
                                            checkboxSelections[doc.id]!.add(opt);
                                          } else {
                                            checkboxSelections[doc.id]!.remove(opt);
                                          }
                                          answers[doc.id] = List.from(checkboxSelections[doc.id]!);
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ))
                              else if (type == 'dropdown')
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  hint: Text("Select an option"),
                                  value: answers[doc.id] as String?,
                                  items: options.map((opt) {
                                    return DropdownMenuItem(value: opt, child: Text(opt));
                                  }).toList(),
                                  onChanged: (val) {
                                    setDialogState(() => answers[doc.id] = val);
                                  },
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Collect text field answers
                    for (var doc in questionDocs) {
                      if (textControllers.containsKey(doc.id)) {
                        answers[doc.id] = textControllers[doc.id]!.text.trim();
                      }
                    }

                    // Validate required fields
                    for (var doc in questionDocs) {
                      Map<String, dynamic> qData = doc.data() as Map<String, dynamic>;
                      bool isRequired = qData['isRequired'] ?? false;
                      if (isRequired) {
                        dynamic answer = answers[doc.id];
                        if (answer == null ||
                            (answer is String && answer.isEmpty) ||
                            (answer is List && answer.isEmpty)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Please answer all required (*) questions"),
                            ),
                          );
                          return;
                        }
                      }
                    }

                    Navigator.pop(context, answers);
                  },
                  child: Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.eventData["title"])),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.eventData["image"] != null && widget.eventData["image"].toString().isNotEmpty
                  ? Image.network(
                widget.eventData["image"],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300], // Background color for placeholder
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  );
                },
              )
                  : Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300], // Placeholder background color
                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              ),
            ),
            SizedBox(height: 10),
            Text(widget.eventData["title"], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text("${widget.eventData["location"]} - ${widget.eventData["type"]}", style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 10),

            // **Event Details**
            Text("Event Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...widget.eventData.entries
                .where((entry) => !["createdBy", "createdByID", "eventCode", "isApproved", "timestamp"].contains(entry.key))
                .map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text("${entry.key}: ${entry.value}", style: TextStyle(fontSize: 16)),
            ))
                .toList(),

            SizedBox(height: 20),

            // **Register Button**
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.eventData["isApproved"] == true 
                    ? Colors.green 
                    : (requestSent 
                        ? Colors.orange 
                        : (widget.eventData["type"] == "Public" ? Colors.blue : Colors.orange)),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                widget.eventData["isApproved"] == true 
                    ? "Accepted - Go to Dashboard" 
                    : (requestSent 
                        ? "Request Pending" 
                        : (widget.eventData["type"] == "Public" ? "Join Event" : "Request Access"))
              ),
              onPressed: () {
                if (widget.eventData["isApproved"] == true) {
                  GlobalState.activeEventCode = widget.eventData["id"];
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (context) => GuestDashboard()), 
                    (route) => false
                  );
                } else if (!requestSent) {
                  registerForEvent();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

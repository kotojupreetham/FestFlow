import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'member_page.dart';

class AddMember extends StatefulWidget {
  final String eventCode; // Parent event code

  const AddMember({Key? key, required this.eventCode}) : super(key: key);

  @override
  _AddMemberState createState() => _AddMemberState();
}

class _AddMemberState extends State<AddMember> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  String email = "";
  bool isLoading = false;

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Check if member already exists
      DocumentSnapshot memberDoc = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .doc(email)
          .get();

      if (memberDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Member already added.")),
        );
        setState(() => isLoading = false);
        return;
      }

      // Add member/{email} in the event structure
      await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .doc(email)
          .set({
        "email": email,
        "isJoined": false,
        "isOnline": false,
        "subEventCode": [],
      });

      // Send invitation email
      await _sendEmailInvitation(email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invitation sent to $email")),
      );
    } catch (e) {
      print("Error adding member: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again.")),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> _sendEmailInvitation(String recipientEmail) async {
    final Email email = Email(
      body: "You have been invited to join the event!\n\nEvent Code: ${widget.eventCode}",
      subject: "Invitation to Join Event",
      recipients: [recipientEmail],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      print("Email sent successfully.");
    } catch (e) {
      print("Failed to send email: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Member")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Enter Member's Email", style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "example@email.com",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value!.isEmpty || !value.contains("@") ? "Enter a valid email" : null,
                onChanged: (value) {
                  setState(() => email = value);
                },
              ),
              SizedBox(height: 20),
              Center(
                child: isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: _addMember,
                  child: Text("Send Invitation"),
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: customFloatingActionButton(onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MemberPage(eventCode: widget.eventCode)),
                  (route) => false,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

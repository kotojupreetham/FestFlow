import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'member_event_page.dart';

class MemberEventDetails extends StatefulWidget {
  final String eventCode;
  final String subEventCode;

  const MemberEventDetails({Key? key, required this.eventCode, required this.subEventCode}) : super(key: key);

  @override
  _MemberEventDetailsState createState() => _MemberEventDetailsState();
}

class _MemberEventDetailsState extends State<MemberEventDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  bool isEditing = false;
  bool canEdit = false;

  Map<String, dynamic>? eventData;
  String? memberId;

  // Controllers for editing fields
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _prizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMemberPermissions();
  }

  Future<void> fetchMemberPermissions() async {
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    memberId = user.email!;

    try {
      // Fetch sub-event details
      DocumentSnapshot subEventDoc = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .doc(widget.subEventCode)
          .get();

      // Fetch member's permissions
      DocumentSnapshot memberDoc = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .doc(memberId)
          .get();

      List<String> subEventCodes = [];
      if (memberDoc.exists && memberDoc.data() != null) {
        Map<String, dynamic> memberData = memberDoc.data() as Map<String, dynamic>;
        subEventCodes = List<String>.from(memberData["subEventCode"] ?? []);
      }

      setState(() {
        if (subEventDoc.exists && subEventDoc.data() != null) {
          eventData = subEventDoc.data() as Map<String, dynamic>;

          // Fill controllers with existing data
          _descriptionController.text = eventData?["description"] ?? "";
          _typeController.text = eventData?["type"] ?? "";
          _priceController.text = eventData?["price"] ?? "";
          _prizeController.text = eventData?["prize"] ?? "";

          // Allow editing only if the sub-event is in subEventCodes
          canEdit = subEventCodes.contains(widget.subEventCode);
        }
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching event details: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> updateEventDetails() async {
    if (!canEdit) return;

    Map<String, dynamic> updatedData = {
      "description": _descriptionController.text.trim(),
      "type": _typeController.text.trim(),
      "price": _priceController.text.trim(),
      "prize": _prizeController.text.trim(),
    };

    try {
      await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .doc(widget.subEventCode)
          .update(updatedData);

      setState(() {
        eventData?.addAll(updatedData);
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sub-Event updated successfully!")),
      );
    } catch (e) {
      print("Error updating event: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update event.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sub-Event Details")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Name (Non-editable)
              Text(eventData?["name"] ?? "Unnamed Event",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

              SizedBox(height: 10),

              // Event Type
              Text("Type", style: TextStyle(fontWeight: FontWeight.bold)),
              canEdit && isEditing
                  ? TextField(controller: _typeController)
                  : Text(eventData?["type"] ?? "N/A", style: TextStyle(color: Colors.grey)),

              SizedBox(height: 10),

              // Event Price
              Text("Price", style: TextStyle(fontWeight: FontWeight.bold)),
              canEdit && isEditing
                  ? TextField(controller: _priceController)
                  : Text(eventData?["price"] ?? "N/A", style: TextStyle(color: Colors.grey)),

              SizedBox(height: 10),

              // Event Prize
              Text("Prize", style: TextStyle(fontWeight: FontWeight.bold)),
              canEdit && isEditing
                  ? TextField(controller: _prizeController)
                  : Text(eventData?["prize"] ?? "N/A", style: TextStyle(color: Colors.grey)),

              SizedBox(height: 10),

              // Event Description
              Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
              canEdit && isEditing
                  ? TextField(
                controller: _descriptionController,
                maxLines: 3,
              )
                  : Text(eventData?["description"] ?? "No description available",
                  style: TextStyle(color: Colors.grey)),

              SizedBox(height: 20),

              // Edit Button (Only for assigned members)
              if (canEdit)
                ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.save : Icons.edit),
                  label: Text(isEditing ? "Save Changes" : "Edit Sub-Event"),
                  onPressed: () {
                    if (isEditing) {
                      updateEventDetails();
                    } else {
                      setState(() => isEditing = true);
                    }
                  },
                ),
            ],
          ),
        ),
      ),


      floatingActionButton: customFloatingActionButton(onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MemberEventPage(eventCode: widget.eventCode)),
                  (route) => false,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

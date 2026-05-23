import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sub_event_page.dart';

class SubEventDetailsPage extends StatefulWidget {
  final String eventCode;
  final String subEventCode;

  const SubEventDetailsPage({Key? key, required this.eventCode, required this.subEventCode}) : super(key: key);

  @override
  _SubEventDetailsPageState createState() => _SubEventDetailsPageState();
}

class _SubEventDetailsPageState extends State<SubEventDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  bool isEditing = false;
  Map<String, dynamic>? eventData;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _customTypeController = TextEditingController();

  List<Map<String, dynamic>> members = []; // Store assigned members with ID, username, and email
  List<Map<String, dynamic>> originalMembers = []; // Store initial list to calculate removals
  List<Map<String, dynamic>> availableMembers = []; // Store all event members for selection

  String? eventType;
  String? eventPrice;
  List<String> eventTypes = ["Sports", "Food", "Entertainment", "Music", "Tech", "Other"];
  List<String> priceOptions = ["Free", "Paid"];

  @override
  void initState() {
    super.initState();
    fetchEventDetails();
  }

  Future<void> fetchEventDetails() async {
    try {
      DocumentSnapshot docSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .doc(widget.subEventCode)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

        setState(() {
          eventData = data;
          _nameController.text = data["name"] ?? "";
          _descriptionController.text = data["description"] ?? "";
          _priceController.text = data["price"] == "Paid" ? (data["prize"] ?? "") : "";
          eventType = data["type"];
          eventPrice = data["price"];
          members = List<Map<String, dynamic>>.from(data["members"] ?? []);
          originalMembers = List<Map<String, dynamic>>.from(data["members"] ?? []);
          isLoading = false;
        });

        fetchAvailableMembers();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching event details: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchAvailableMembers() async {
    try {
      QuerySnapshot memberSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .get();

      setState(() {
        availableMembers = memberSnapshot.docs.map((doc) {
          return {
            "id": doc.id,
            "username": doc["username"],
            "email": doc["email"],
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching available members: $e");
    }
  }

  Future<void> updateEventDetails() async {
    if (_nameController.text.trim().isEmpty || members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Event name and at least one member are required!")),
      );
      return;
    }

    Map<String, dynamic> updatedData = {
      "name": _nameController.text.trim(),
      "description": _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      "prize": eventPrice == "Paid" ? _priceController.text.trim() : null,
      "type": eventType == "Other" ? _customTypeController.text.trim() : eventType,
      "price": eventPrice,
      "members": members, // Store members with ID, username, and email
    };

    try {
      DocumentReference eventRef = _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .doc(widget.subEventCode);

      // Update the sub-event
      await eventRef.update(updatedData);

      // Calculate arrays for assignment sync
      List<String> oldMemberIds = originalMembers.map((m) => m["id"].toString()).toList();
      List<String> newMemberIds = members.map((m) => m["id"].toString()).toList();

      List<String> addedMembers = newMemberIds.where((id) => !oldMemberIds.contains(id)).toList();
      List<String> removedMembers = oldMemberIds.where((id) => !newMemberIds.contains(id)).toList();

      // Add to new members
      for (var memberId in addedMembers) {
        await _firestore
            .collection("events")
            .doc(widget.eventCode)
            .collection("member")
            .doc(memberId)
            .update({
          "subEventCode": FieldValue.arrayUnion([widget.subEventCode]),
        });
      }

      // Remove from unselected members
      for (var memberId in removedMembers) {
        await _firestore
            .collection("events")
            .doc(widget.eventCode)
            .collection("member")
            .doc(memberId)
            .update({
          "subEventCode": FieldValue.arrayRemove([widget.subEventCode]),
        });
      }

      setState(() {
        eventData?.addAll(updatedData);
        originalMembers = List<Map<String, dynamic>>.from(members);
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Event updated successfully!")),
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
              // Event Name
              isEditing
                  ? TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Event Name *", labelStyle: TextStyle(fontWeight: FontWeight.bold)),
              )
                  : Text(eventData?["name"] ?? "No Name",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

              SizedBox(height: 10),

              // Event Type
              Text("Event Type", style: TextStyle(fontWeight: FontWeight.bold)),
              isEditing
                  ? DropdownButtonFormField(
                value: eventType,
                items: eventTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => eventType = value as String?),
              )
                  : Text(eventData?["type"] ?? "N/A", style: TextStyle(fontSize: 16, color: Colors.black)),

              SizedBox(height: 10),

              // Event Price
              Text("Event Price", style: TextStyle(fontWeight: FontWeight.bold)),
              isEditing
                  ? DropdownButtonFormField(
                value: eventPrice,
                items: priceOptions.map((price) => DropdownMenuItem(value: price, child: Text(price))).toList(),
                onChanged: (value) => setState(() => eventPrice = value as String?),
              )
                  : Text(eventData?["price"] ?? "N/A", style: TextStyle(fontSize: 16, color: Colors.black)),

              SizedBox(height: 10),

              // Event Description
              Text("Event Description", style: TextStyle(fontWeight: FontWeight.bold)),
              isEditing
                  ? TextField(controller: _descriptionController, maxLines: 3)
                  : Text(eventData?["description"] ?? "No description available", style: TextStyle(fontSize: 16)),

              SizedBox(height: 20),

              // Members List
              Text("Members", style: TextStyle(fontWeight: FontWeight.bold)),
              if (isEditing)
                Column(
                  children: availableMembers.map((member) {
                    return CheckboxListTile(
                      title: Text(member["username"]),
                      subtitle: Text(member["email"]),
                      value: members.any((m) => m["id"] == member["id"]),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            members.add(member);
                          } else {
                            members.removeWhere((m) => m["id"] == member["id"]);
                          }
                        });
                      },
                    );
                  }).toList(),
                )
              else
                Column(children: members.map((member) => ListTile(title: Text(member["username"]), subtitle: Text(member["email"]))).toList()),

              SizedBox(height: 20),

              // Edit & Save Button
              ElevatedButton.icon(
                icon: Icon(isEditing ? Icons.save : Icons.edit),
                label: Text(isEditing ? "Save Changes" : "Edit Event"),
                onPressed: isEditing ? updateEventDetails : () => setState(() => isEditing = true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

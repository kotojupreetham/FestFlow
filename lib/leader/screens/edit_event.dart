import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'leader_dashboard.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;

  const EditEventScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class CustomFieldData {
  TextEditingController keyController;
  TextEditingController valueController;

  CustomFieldData({required String key, required String value})
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);
}

class _EditEventScreenState extends State<EditEventScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _ageLimitController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _eventCapacityController = TextEditingController();
  final TextEditingController _startingDateController = TextEditingController();

  List<CustomFieldData> customFields = [];
  bool isLoading = true;
  Map<String, dynamic>? eventData;
  User? _user;

  @override
  void initState() {
    super.initState();
    fetchEventDetails();
  }

  Future<void> fetchEventDetails() async {
    try {
      _user = _auth.currentUser;

      // Read details from events/{eventId}.details map field
      DocumentSnapshot eventDoc = await _firestore
          .collection("events")
          .doc(widget.eventId)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;

        if (data.containsKey("details") && data["details"] != null) {
          Map<String, dynamic> details = Map<String, dynamic>.from(data["details"]);

          setState(() {
            eventData = details;
            _titleController.text = (details["title"] ?? "").toString();
            _descriptionController.text = (details["description"] ?? "").toString();
            _categoryController.text = (details["category"] ?? "").toString();
            _typeController.text = (details["type"] ?? "").toString();
            _ageLimitController.text = (details["ageLimit"] ?? "").toString();
            _imageController.text = (details["image"] ?? "").toString();
            _eventCapacityController.text = (details["eventCapacity"] ?? "").toString();
            _startingDateController.text = (details["startingDate"] ?? "").toString();

            // Load custom fields dynamically
            details.forEach((key, value) {
              if (!["createdBy", "createdByID", "eventCode", "isApproved", "timestamp",
                    "location", "latitude", "longitude"].contains(key) &&
                  !["title", "description", "category", "type", "ageLimit",
                    "image", "eventCapacity", "startingDate"].contains(key)) {
                customFields.add(CustomFieldData(key: key, value: value.toString()));
              }
            });

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

  void addCustomField() {
    setState(() {
      customFields.add(CustomFieldData(key: "", value: ""));
    });
  }

  Future<void> updateEventDetails() async {
    Map<String, dynamic> eventEditData = {
      "title": _titleController.text,
      "description": _descriptionController.text,
      "category": _categoryController.text,
      "type": _typeController.text,
      "ageLimit": _ageLimitController.text,
      "image": _imageController.text,
      "eventCapacity": _eventCapacityController.text,
      "startingDate": _startingDateController.text,
    };

    // Add custom fields
    for (var field in customFields) {
      String key = field.keyController.text.trim();
      String value = field.valueController.text.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        eventEditData[key] = value;
      }
    }

    // Preserve fields that shouldn't be overwritten
    if (eventData != null) {
      for (String preserveKey in ["createdBy", "createdByID", "eventCode", "isApproved", "timestamp", "location", "latitude", "longitude"]) {
        if (eventData!.containsKey(preserveKey)) {
          eventEditData[preserveKey] = eventData![preserveKey];
        }
      }
    }

    try {
      _user = _auth.currentUser;

      // Update events/{eventId}.details map field
      await _firestore
          .collection("events")
          .doc(widget.eventId)
          .update({"details": eventEditData});

      // Also sync to leader/{email}/events/{eventCode}
      if (_user?.email != null) {
        await _firestore
            .collection("leader")
            .doc(_user!.email)
            .collection("events")
            .doc(widget.eventId)
            .update(eventEditData);
      }

      print("Event updated successfully!");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Event updated successfully!")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LeaderDashboard()),
            (route) => false,
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
      appBar: AppBar(title: Text("Edit Event")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image Preview
              _imageController.text.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _imageController.text,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
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

              SizedBox(height: 20),

              // Editable Fields
              TextField(controller: _titleController, decoration: InputDecoration(labelText: "Event Title")),
              TextField(controller: _descriptionController, decoration: InputDecoration(labelText: "Description"), maxLines: 3),
              TextField(controller: _categoryController, decoration: InputDecoration(labelText: "Category")),
              TextField(controller: _typeController, decoration: InputDecoration(labelText: "Type")),
              TextField(controller: _ageLimitController, decoration: InputDecoration(labelText: "Age Limit")),
              TextField(controller: _imageController, decoration: InputDecoration(labelText: "Image URL")),
              TextField(controller: _eventCapacityController, decoration: InputDecoration(labelText: "Event Capacity")),
              TextField(controller: _startingDateController, decoration: InputDecoration(labelText: "Starting Date")),
// Display custom fields dynamically
              Text("Custom Fields:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...customFields.map((field) {
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: field.keyController,
                        decoration: InputDecoration(labelText: "Enter field name"),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: field.valueController,
                        decoration: InputDecoration(labelText: "Enter value"),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => setState(() => customFields.remove(field)),
                    ),
                  ],
                );
              }).toList(),

              SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text("Add Custom Field"),
                onPressed: addCustomField,
              ),

              SizedBox(height: 20),

              ElevatedButton.icon(icon: Icon(Icons.save), label: Text("Save Changes"), onPressed: updateEventDetails),
            ],
          ),
        ),
      ),
    );
  }
}

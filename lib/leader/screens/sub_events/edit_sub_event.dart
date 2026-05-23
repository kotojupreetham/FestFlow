import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sub_event_page.dart';

class EditSubEvent extends StatefulWidget {
  final String eventCode;
  final Map<String, dynamic> subEventData;

  const EditSubEvent({Key? key, required this.eventCode, required this.subEventData}) : super(key: key);

  @override
  _EditSubEventState createState() => _EditSubEventState();
}

class _EditSubEventState extends State<EditSubEvent> {
  final _formKey = GlobalKey<FormState>();

  late String subEventCode;
  late String eventName;
  late TextEditingController _typeController;
  late TextEditingController _priceController;
  late TextEditingController _descController;

  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> selectedMembers = [];
  List<String> originalMemberIds = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    subEventCode = widget.subEventData["subEventCode"];
    eventName = widget.subEventData["name"] ?? "";
    _typeController = TextEditingController(text: widget.subEventData["type"] ?? "");
    _priceController = TextEditingController(text: widget.subEventData["price"]?.toString() ?? "");
    _descController = TextEditingController(text: widget.subEventData["description"] ?? "");

    if (widget.subEventData["members"] != null) {
      for (var m in widget.subEventData["members"]) {
        selectedMembers.add(Map<String, dynamic>.from(m));
        originalMemberIds.add(m["id"]);
      }
    }

    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      QuerySnapshot membersSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .get();

      setState(() {
        members = membersSnapshot.docs
            .where((doc) => doc.id != "init")
            .map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            "id": doc.id,
            "username": data.containsKey("username") ? data["username"] : "Unknown",
            "email": data.containsKey("email") ? data["email"] : doc.id,
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching members: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateEventInFirestore() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (selectedMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please assign at least one member.")),
        );
        return;
      }

      try {
        DocumentReference eventDocRef = _firestore.collection("events").doc(widget.eventCode);

        List<Map<String, dynamic>> membersData = selectedMembers.map((member) {
          return {
            "id": member["id"],
            "username": member["username"],
            "email": member["email"],
          };
        }).toList();

        await eventDocRef.collection("sub-events").doc(subEventCode).update({
          "name": eventName,
          "type": _typeController.text.trim().isEmpty ? null : _typeController.text.trim(),
          "price": _priceController.text.trim().isEmpty ? null : double.tryParse(_priceController.text.trim())?.toString() ?? _priceController.text.trim(),
          "description": _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          "members": membersData,
        });

        // Handle Member Arrays:
        // 1. Add subEventCode to newly selected members
        List<String> newMemberIds = selectedMembers.map((m) => m["id"] as String).toList();
        for (String id in newMemberIds) {
          if (!originalMemberIds.contains(id)) {
            await eventDocRef.collection("member").doc(id).update({
              "subEventCode": FieldValue.arrayUnion([subEventCode]),
            });
          }
        }

        // 2. Remove subEventCode from unselected members
        for (String id in originalMemberIds) {
          if (!newMemberIds.contains(id)) {
            await eventDocRef.collection("member").doc(id).update({
              "subEventCode": FieldValue.arrayRemove([subEventCode]),
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sub-Event updated!")),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SubEventPage(eventCode: widget.eventCode)),
              (route) => false,
        );
      } catch (e) {
        print("Error updating sub-event: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update Sub-Event. Try again!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Sub-Event")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Sub-Event Name
              TextFormField(
                initialValue: eventName,
                decoration: InputDecoration(
                  labelText: "Sub-Event Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                validator: (value) => value == null || value.isEmpty ? "Required" : null,
                onSaved: (value) => eventName = value!,
              ),

              SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(
                  labelText: "Type (e.g. Solo, Group) [Optional]",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: "Price [Optional]",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: "Description [Optional]",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),

              SizedBox(height: 20),
              Text("Assign Members:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text("${selectedMembers.length} of ${members.length} selected", style: TextStyle(color: Colors.grey)),
              SizedBox(height: 8),

              members.isEmpty
                  ? Center(child: Text("No members available"))
                  : Column(
                children: members.map((member) {
                  return CheckboxListTile(
                    title: Text(member["username"]),
                    subtitle: Text(member["email"]),
                    value: selectedMembers.any((m) => m["id"] == member["id"]),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedMembers.add(member);
                        } else {
                          selectedMembers.removeWhere((m) => m["id"] == member["id"]);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text("Save Changes"),
                onPressed: () => _updateEventInFirestore(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: customFloatingActionButton(onPressed: () {
        Navigator.pop(context);
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

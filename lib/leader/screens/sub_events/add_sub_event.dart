import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'sub_event_page.dart';

class AddSubEvent extends StatefulWidget {
  final String eventCode;

  const AddSubEvent({Key? key, required this.eventCode}) : super(key: key);

  @override
  _AddSubEventState createState() => _AddSubEventState();
}

class _AddSubEventState extends State<AddSubEvent> {
  final _formKey = GlobalKey<FormState>();

  String eventName = "";
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> selectedMembers = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
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
      });
    } catch (e) {
      print("Error fetching members: $e");
    }
  }

  String generateSubEventCode() {
    final Random random = Random();
    int randomDigits = 100 + random.nextInt(900);
    return "${widget.eventCode}-$randomDigits";
  }

  Future<void> _saveEventToFirestore() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (selectedMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please assign at least one member.")),
        );
        return;
      }

      String subEventCode = generateSubEventCode();

      try {
        DocumentReference eventDocRef = _firestore.collection("events").doc(widget.eventCode);

        List<Map<String, dynamic>> membersData = selectedMembers.map((member) {
          return {
            "id": member["id"],
            "username": member["username"],
            "email": member["email"],
          };
        }).toList();

        // Leader only sets name + members. Members fill in the rest.
        await eventDocRef.collection("sub-events").doc(subEventCode).set({
          "subEventCode": subEventCode,
          "name": eventName,
          "type": _typeController.text.trim().isEmpty ? null : _typeController.text.trim(),
          "price": _priceController.text.trim().isEmpty ? null : double.tryParse(_priceController.text.trim())?.toString() ?? _priceController.text.trim(),
          "description": _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          "members": membersData,
          "createdAt": FieldValue.serverTimestamp(),
        });

        // Update subEventCode in each selected member's document
        for (var member in selectedMembers) {
          await eventDocRef.collection("member").doc(member["id"]).update({
            "subEventCode": FieldValue.arrayUnion([subEventCode]),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sub-Event '$eventName' created! Members can now fill in the details.")),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SubEventPage(eventCode: widget.eventCode)),
              (route) => false,
        );
      } catch (e) {
        print("Error adding sub-event: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add Sub-Event. Try again!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Sub-Event")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Info card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Create a sub-event and assign members. They will fill in the type, price, and description.",
                          style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Sub-Event Name
              TextFormField(
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
                  ? Center(child: CircularProgressIndicator())
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
                label: Text("Create Sub-Event"),
                onPressed: () => _saveEventToFirestore(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: customFloatingActionButton(onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SubEventPage(eventCode: widget.eventCode)),
                  (route) => false,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

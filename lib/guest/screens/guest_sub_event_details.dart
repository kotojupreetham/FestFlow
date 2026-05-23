import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuestSubEventDetails extends StatefulWidget {
  final String eventCode;
  final String subEventCode;

  const GuestSubEventDetails({Key? key, required this.eventCode, required this.subEventCode})
      : super(key: key);

  @override
  _GuestSubEventDetailsState createState() => _GuestSubEventDetailsState();
}

class _GuestSubEventDetailsState extends State<GuestSubEventDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  Map<String, dynamic>? subEventData;
  List<Map<String, dynamic>> eventMembers = [];

  @override
  void initState() {
    super.initState();
    fetchSubEventDetails();
  }

  Future<void> fetchSubEventDetails() async {
    try {
      // Fetch sub-event details
      DocumentSnapshot docSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .doc(widget.subEventCode)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          subEventData = docSnapshot.data() as Map<String, dynamic>;
        });
      }

      // Fetch event members
      QuerySnapshot memberSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("members")
          .get();

      setState(() {
        eventMembers = memberSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            "username": data["username"] ?? "Unknown",
            "role": data["role"] ?? "Member"
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching sub-event details: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sub-Event Details")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : subEventData == null
          ? Center(child: Text("Sub-event details not found"))
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // **Sub-Event Name**
              Text(
                subEventData!["name"] ?? "Unnamed Event",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // **Sub-Event Type & Price**
              Text("Type: ${subEventData!["type"] ?? "N/A"}", style: TextStyle(fontSize: 16)),
              Text("Price: ${subEventData!["price"] ?? "Free"}", style: TextStyle(fontSize: 16)),

              SizedBox(height: 10),

              // **Sub-Event Description**
              Text(
                subEventData!["description"] ?? "No description available",
                style: TextStyle(fontSize: 16),
              ),

              SizedBox(height: 20),


            ],
          ),
        ),
      ),
    );
  }
}

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'member_dashboard.dart';

class MemberAnalyticsScreen extends StatefulWidget {
  final String eventCode;

  const MemberAnalyticsScreen({Key? key, required this.eventCode}) : super(key: key);

  @override
  _MemberAnalyticsScreenState createState() => _MemberAnalyticsScreenState();
}

class _MemberAnalyticsScreenState extends State<MemberAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  int totalSubEvents = 0;
  int mySubEvents = 0;
  int totalMembers = 0;
  int onlineMembers = 0;
  List<Map<String, dynamic>> mySubEventDetails = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // Total sub-events
      QuerySnapshot subEventsSnap = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .get();
      List<QueryDocumentSnapshot> subEventDocs = subEventsSnap.docs.where((d) => d.id != "init").toList();

      // My assigned sub-events
      DocumentSnapshot memberDoc = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .doc(user.email!)
          .get();

      List<String> mySubEventCodes = [];
      if (memberDoc.exists && memberDoc.data() != null) {
        Map<String, dynamic> mData = memberDoc.data() as Map<String, dynamic>;
        if (mData.containsKey("subEventCode") && mData["subEventCode"] is List) {
          mySubEventCodes = List<String>.from(mData["subEventCode"]);
        }
      }

      // Fetch details for my sub-events
      List<Map<String, dynamic>> myDetails = [];
      for (var doc in subEventDocs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (mySubEventCodes.contains(doc.id)) {
          data["subEventCode"] = doc.id;
          myDetails.add(data);
        }
      }

      // Members count + online
      QuerySnapshot membersSnap = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .get();
      List<QueryDocumentSnapshot> memberDocs = membersSnap.docs.where((d) => d.id != "init").toList();
      int online = 0;
      for (var doc in memberDocs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data["isOnline"] == true) online++;
      }

      setState(() {
        totalSubEvents = subEventDocs.length;
        mySubEvents = mySubEventCodes.length;
        totalMembers = memberDocs.length;
        onlineMembers = online;
        mySubEventDetails = myDetails;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching analytics: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Analytics")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  Row(
                    children: [
                      _buildStatCard("My Sub-Events", "$mySubEvents", Icons.event, Colors.green),
                      SizedBox(width: 12),
                      _buildStatCard("Total Sub-Events", "$totalSubEvents", Icons.event_note, Colors.blue),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatCard("Total Members", "$totalMembers", Icons.people, Colors.orange),
                      SizedBox(width: 12),
                      _buildStatCard("Online Now", "$onlineMembers", Icons.circle, Colors.teal),
                    ],
                  ),

                  SizedBox(height: 24),
                  Text("My Assigned Sub-Events", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),

                  mySubEventDetails.isEmpty
                      ? Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("You are not assigned to any sub-events yet.", style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : Column(
                          children: mySubEventDetails.map((subEvent) {
                            String name = subEvent["name"] ?? "Unnamed";
                            String type = subEvent["type"] ?? "Not set";
                            String price = subEvent["price"] ?? "Not set";
                            String description = subEvent["description"] ?? "No description yet";
                            List members = subEvent["members"] ?? [];

                            return Card(
                              margin: EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 6),
                                    _infoRow(Icons.category, "Type", type),
                                    _infoRow(Icons.attach_money, "Price", price),
                                    _infoRow(Icons.description, "Description", description),
                                    _infoRow(Icons.people, "Team Size", "${members.length} members"),

                                    // Completion indicator
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: _getCompletionScore(subEvent),
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getCompletionScore(subEvent) == 1.0 ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "${(_getCompletionScore(subEvent) * 100).toInt()}% details filled",
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),

      floatingActionButton: customFloatingActionButton(onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MemberDashboard()),
                  (route) => false,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  double _getCompletionScore(Map<String, dynamic> data) {
    int filled = 0;
    int total = 3; // type, price, description
    if (data["type"] != null && data["type"].toString().isNotEmpty) filled++;
    if (data["price"] != null && data["price"].toString().isNotEmpty) filled++;
    if (data["description"] != null && data["description"].toString().isNotEmpty) filled++;
    return filled / total;
  }
}

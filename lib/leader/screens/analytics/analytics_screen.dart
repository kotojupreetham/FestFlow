
//analytics_screen.dart

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festflow/home/services/gemini_service.dart';
import '../leader_dashboard.dart';

class AnalyticsScreen extends StatefulWidget {
  final String eventCode;

  const AnalyticsScreen({Key? key, required this.eventCode}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool isGeneratingReport = false;

  int subEventCount = 0;
  int memberCount = 0;
  int onlineMembers = 0;
  int offlineMembers = 0;
  List<Map<String, dynamic>> subEventStats = [];
  String? aiReport;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      // Fetch sub-events
      QuerySnapshot subEventsSnap = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .get();

      List<Map<String, dynamic>> subs = subEventsSnap.docs
          .where((doc) => doc.id != "init")
          .map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        List members = data["members"] ?? [];
        return {
          "name": data["name"] ?? "Unnamed",
          "type": data["type"] ?? "N/A",
          "price": data["price"] ?? "Free",
          "memberCount": members.length,
        };
      }).toList();

      // Fetch members
      QuerySnapshot membersSnap = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .get();

      int total = 0;
      int online = 0;
      int offline = 0;
      for (var doc in membersSnap.docs) {
        if (doc.id == "init") continue;
        total++;
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey("isOnline") && data["isOnline"] == true) {
          online++;
        } else {
          offline++;
        }
      }

      setState(() {
        subEventCount = subs.length;
        subEventStats = subs;
        memberCount = total;
        onlineMembers = online;
        offlineMembers = offline;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching analytics: $e");
      setState(() => isLoading = false);
    }
  }

  String _buildStatsText() {
    StringBuffer sb = StringBuffer();
    sb.writeln("Event Code: ${widget.eventCode}");
    sb.writeln("Total Sub-Events: $subEventCount");
    sb.writeln("Total Members: $memberCount");
    sb.writeln("Online Members: $onlineMembers");
    sb.writeln("Offline Members: $offlineMembers");
    sb.writeln("");
    sb.writeln("Sub-Event Breakdown:");
    for (var sub in subEventStats) {
      sb.writeln("  - ${sub['name']} | Type: ${sub['type']} | Price: ${sub['price']} | Members Assigned: ${sub['memberCount']}");
    }
    return sb.toString();
  }

  Future<void> _generateAIReport() async {
    setState(() => isGeneratingReport = true);
    String report = await GeminiService.generateEventReport(_buildStatsText());
    setState(() {
      aiReport = report;
      isGeneratingReport = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Analytics")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Stats Cards
                  Row(
                    children: [
                      _statCard("Sub-Events", "$subEventCount", Icons.event, Colors.blue),
                      SizedBox(width: 8),
                      _statCard("Members", "$memberCount", Icons.people, Colors.green),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _statCard("Online", "$onlineMembers", Icons.circle, Colors.teal),
                      SizedBox(width: 8),
                      _statCard("Offline", "$offlineMembers", Icons.circle_outlined, Colors.red),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Sub-Event Breakdown
                  Text("📊 Sub-Event Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  if (subEventStats.isEmpty)
                    Text("No sub-events found.", style: TextStyle(color: Colors.grey))
                  else
                    ...subEventStats.map((sub) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(Icons.event_note, color: Colors.deepPurple),
                          title: Text(sub["name"], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Type: ${sub['type']} | Price: ${sub['price']}"),
                          trailing: Chip(
                            label: Text("${sub['memberCount']} members"),
                            backgroundColor: Colors.blue[50],
                          ),
                        ),
                      );
                    }).toList(),

                  SizedBox(height: 20),

                  // AI Report Section
                  Divider(thickness: 2),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("🤖 AI Event Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: isGeneratingReport ? null : _generateAIReport,
                        icon: isGeneratingReport
                            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(Icons.auto_awesome),
                        label: Text(isGeneratingReport ? "Generating..." : "Generate"),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (aiReport != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SelectableText(
                        aiReport!,
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text("Tap 'Generate' to get an AI-powered event report.", style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                ],
              ),
            ),

      floatingActionButton: customFloatingActionButton(onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LeaderDashboard()),
                  (route) => false,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                  Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

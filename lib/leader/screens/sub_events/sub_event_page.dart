import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../leader_dashboard.dart';
import 'add_sub_event.dart';
import 'manage_sub_event.dart';
import 'search_sub_event.dart';
import 'sub_event_details.dart';

class SubEventPage extends StatefulWidget {
  final String eventCode; // Parent event code to fetch sub-events

  const SubEventPage({Key? key, required this.eventCode}) : super(key: key);

  @override
  _SubEventPageState createState() => _SubEventPageState();
}

class _SubEventPageState extends State<SubEventPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> subEvents = [];
  bool isLoading = true;
  String selectedSort = "A-Z";

  @override
  void initState() {
    super.initState();
    fetchSubEvents();
  }

  Future<void> fetchSubEvents() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .orderBy("createdAt", descending: false)
          .get();

      setState(() {
        subEvents = querySnapshot.docs
            .where((doc) => doc.id != "init") // Exclude init doc
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching sub-events: $e");
      setState(() => isLoading = false);
    }
  }

  void _sortEvents(String sortType) {
    setState(() {
      selectedSort = sortType;
      if (sortType == "A-Z") {
        subEvents.sort((a, b) => (a["name"] ?? "").compareTo(b["name"] ?? ""));
      } else if (sortType == "Z-A") {
        subEvents.sort((a, b) => (b["name"] ?? "").compareTo(a["name"] ?? ""));
      }
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              title: Text("Sort A-Z"),
              onTap: () {
                _sortEvents("A-Z");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("Sort Z-A"),
              onTap: () {
                _sortEvents("Z-A");
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sub-Events"),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIconWithText(Icons.add, "Add Sub-Event", Colors.blue, AddSubEvent(eventCode: widget.eventCode)),
                _buildIconWithText(Icons.settings, "Manage Sub-Event", Colors.green, ManageSubEvent(eventCode: widget.eventCode)),
                _buildIconWithText(Icons.search, "Search Sub-Event", Colors.orange, SearchSubEventPage(eventCode: widget.eventCode)),
              ],
            ),
          ),

          Divider(thickness: 3, color: Colors.black),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : subEvents.isEmpty
                ? Center(child: Text("No sub-events available"))
                : ListView.builder(
              itemCount: subEvents.length,
              itemBuilder: (context, index) {
                final subEvent = subEvents[index];
                return ListTile(
                  leading: Icon(Icons.event),
                  title: Text(subEvent["name"] ?? "Unnamed Sub-Event"),
                  subtitle: Text(subEvent["description"] ?? "No description available"),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubEventDetailsPage(
                          eventCode: widget.eventCode,
                          subEventCode: subEvent["subEventCode"],
                        ),
                      ),
                    );
                  },

                );
              },
            ),
          ),
        ],
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

  Widget _buildIconWithText(IconData icon, String text, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sub_event_page.dart';
import 'sub_event_details.dart';

class SearchSubEventPage extends StatefulWidget {
  final String eventCode; // Parent event code to search sub-events

  const SearchSubEventPage({Key? key, required this.eventCode}) : super(key: key);

  @override
  _SearchSubEventPageState createState() => _SearchSubEventPageState();
}

class _SearchSubEventPageState extends State<SearchSubEventPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allEvents = [];
  List<Map<String, dynamic>> filteredEvents = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("sub-events")
          .orderBy("createdAt", descending: false)
          .get();

      setState(() {
        allEvents = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data["id"] = doc.id; // Store Firestore document ID
          return data;
        }).toList();
        filteredEvents = allEvents;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching events: $e");
      setState(() => isLoading = false);
    }
  }

  void _filterEvents(String query) {
    setState(() {
      searchQuery = query;
      filteredEvents = allEvents
          .where((event) => event["name"].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Events")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search Events",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterEvents,
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredEvents.isEmpty
                ? Center(child: Text("No events found"))
                : ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return ListTile(
                  title: Text(event["name"] ?? "Unnamed Event"),
                  subtitle: Text(event["description"] ?? "No description available"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubEventDetailsPage(
                          eventCode: widget.eventCode,
                          subEventCode: event["id"],
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
              MaterialPageRoute(builder: (context) => SubEventPage(eventCode: widget.eventCode)),
                  (route) => false,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

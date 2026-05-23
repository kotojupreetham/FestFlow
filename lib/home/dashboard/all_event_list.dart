import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'about_event_details.dart';
import 'event_qr_scanner.dart';

class AllEventList extends StatefulWidget {
  @override
  _AllEventListState createState() => _AllEventListState();
}

class _AllEventListState extends State<AllEventList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> filteredEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllEventCodes();
  }

  Future<void> fetchAllEventCodes() async {
    try {
      print("[AllEventList] Fetching event codes from 'events' collection...");
      QuerySnapshot eventSnapshot = await _firestore.collection("events").get();
      
      List<String> eventCodes = eventSnapshot.docs.map((doc) => doc.id).toList();
      print("[AllEventList] Found ${eventCodes.length} events: $eventCodes");

      for (String eventCode in eventCodes) {
        await fetchEventDetails(eventCode);
      }

      print("[AllEventList] Fetched all details. Updating UI...");
      setState(() {
        filteredEvents = List.from(events);
        isLoading = false;
      });
    } catch (e) {
      print("[AllEventList] Error fetching event codes: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchEventDetails(String code) async {
    print("[AllEventList] Fetching details for event code: $code");
    try {
      DocumentSnapshot eventDoc = await _firestore
          .collection("events")
          .doc(code)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
        print("[AllEventList] $code exists, data keys: ${data.keys.toList()}");

        if (data.containsKey("details") && data["details"] != null) {
          // Extract the details map directly
          Map<String, dynamic> firstEvent = Map<String, dynamic>.from(data["details"]);
          print("[AllEventList] $code added to events list.");

          setState(() {
            events.add({
              "id": code, // Store eventCode
              "title": firstEvent["title"] ?? "Untitled Event",
              "date": firstEvent["startingDate"] is Timestamp
                  ? firstEvent["startingDate"].toDate()
                  : DateTime.tryParse(firstEvent["startingDate"] ?? "") ?? DateTime.now(),
              "location": firstEvent["location"] ?? "No Location",
              "type": firstEvent["type"] ?? "Unknown",
              "image": firstEvent["image"] ?? "https://via.placeholder.com/150",
              "faq": firstEvent["faq"] ?? [],
            });
          });
        }
      } else {
        print("[AllEventList] $code has no details document.");
      }
    } catch (e) {
      print("[AllEventList] Error fetching event details for $code: $e");
    }
  }


  void filterEvents(String query) {
    setState(() {
      filteredEvents = events.where((event) {
        return event["title"].toLowerCase().contains(query.toLowerCase()) ||
            event["location"].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  String getCountdownTime(DateTime eventDate) {
    Duration difference = eventDate.difference(DateTime.now());
    if (difference.isNegative) return "Happening Now!";
    return "Starts in ${difference.inHours}h ${difference.inMinutes % 60}m";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Events"),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventQRScanner()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterEvents,
              decoration: InputDecoration(
                labelText: "Search Events",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: Hero(
                      tag: event["id"],
                      child: (event["image"] != null && event["image"].toString().startsWith("http"))
                          ? Image.network(
                        event["image"],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: Icon(Icons.event, color: Colors.grey[700]),
                          );
                        },
                      )
                          : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: Icon(Icons.event, color: Colors.grey[700]),
                      ),

                    ),

                    title: Text(event["title"]),
                    subtitle: Text(
                      "${event["location"]} - ${DateFormat.yMMMd().format(event["date"])}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(event["type"], style: TextStyle(color: Colors.blue)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AboutEventDetailsPage(eventData: event),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

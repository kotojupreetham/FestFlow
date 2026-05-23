import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'member_page.dart';
import 'member_details.dart';

class SearchMembers extends StatefulWidget {
  final String eventCode;

  const SearchMembers({Key? key, required this.eventCode}) : super(key: key);

  @override
  _SearchMembersState createState() => _SearchMembersState();
}

class _SearchMembersState extends State<SearchMembers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allMembers = [];
  List<Map<String, dynamic>> filteredMembers = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .get();

      setState(() {
        allMembers = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data["id"] = doc.id; // Store Firestore document ID
          return data;
        }).toList();
        filteredMembers = allMembers;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching members: $e");
      setState(() => isLoading = false);
    }
  }

  void _filterMembers(String query) {
    setState(() {
      searchQuery = query;
      filteredMembers = allMembers
          .where((member) =>
      (member["username"] ?? "").toLowerCase().contains(query.toLowerCase()) ||
          (member["email"] ?? "").toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Members")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search Members",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterMembers,
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredMembers.isEmpty
                ? Center(child: Text("No members found"))
                : ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member = filteredMembers[index];
                return ListTile(
                  leading: Icon(Icons.person),
                  title: Text(member["username"] ?? "Unknown"),
                  subtitle: Text(member["email"] ?? "No email"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberDetails(
                          eventCode: widget.eventCode,
                          memberId: member["id"],
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
              MaterialPageRoute(builder: (context) => MemberPage(eventCode: widget.eventCode)),
                  (route) => false,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

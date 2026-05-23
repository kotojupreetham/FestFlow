import 'package:festflow/theme/button/floating_Action_Button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'member_page.dart';

class ManageMembers extends StatefulWidget {
  final String eventCode;

  const ManageMembers({Key? key, required this.eventCode}) : super(key: key);

  @override
  _ManageMembersState createState() => _ManageMembersState();
}

class _ManageMembersState extends State<ManageMembers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      QuerySnapshot memberSnapshot = await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .get();

      setState(() {
        members = memberSnapshot.docs
            .where((doc) => doc.id != "init") // Exclude init doc
            .map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data["id"] = doc.id; // doc.id = email
          return data;
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching members: $e");
      setState(() => isLoading = false);
    }
  }

  void _confirmDelete(String memberId, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Deletion"),
        content: Text("Are you sure you want to remove $username from the event?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => _deleteMember(memberId),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  Future<void> _deleteMember(String memberId) async {
    try {
      // Remove from event's member sub-collection (memberId = email)
      await _firestore
          .collection("events")
          .doc(widget.eventCode)
          .collection("member")
          .doc(memberId)
          .delete();

      // Remove from users/{email}/events/{eventCode}
      await _firestore
          .collection("users")
          .doc(memberId)
          .collection("events")
          .doc(widget.eventCode)
          .delete();

      setState(() {
        members.removeWhere((member) => member["id"] == memberId);
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Member removed successfully!")),
      );
    } catch (e) {
      print("Error removing member: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove member.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Members")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : members.isEmpty
          ? Center(child: Text("No members found."))
          : ListView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return ListTile(
            leading: Icon(Icons.person),
            title: Text(member["username"] ?? "Unknown"),
            subtitle: Text(member["email"] ?? member["id"] ?? "No email"),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(member["id"], member["username"] ?? "this member"),
            ),
          );
        },
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

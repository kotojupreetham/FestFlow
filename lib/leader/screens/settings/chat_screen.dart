
//chat_screen.dart


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../leader_dashboard.dart';

class ChatScreen extends StatefulWidget {
  final String eventCode;

  const ChatScreen({Key? key, required this.eventCode}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedRecipient = "Everyone"; // Default recipient
  final TextEditingController _messageController = TextEditingController();
  User? _user;
  String _username = "Leader";

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    if (_user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('leader').doc(_user!.email).get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _username = (userDoc.data() as Map<String, dynamic>)['username'] ?? "Leader";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
        centerTitle: true,
        actions: [
          // Close button in AppBar
          IconButton(
            icon: Icon(Icons.close, color: Colors.black38),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LeaderDashboard()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // "Sent to" dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text("Sent to: ", style: TextStyle(fontSize: 16)),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedRecipient,
                  onChanged: (newValue) {
                    setState(() {
                      selectedRecipient = newValue!;
                    });
                  },
                  items: ["Everyone", "Host Only"]
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Chat messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("events")
                  .doc(widget.eventCode)
                  .collection("chats")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No messages yet."));
                }

                var docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Auto-scroll to bottom
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var message = docs[index].data() as Map<String, dynamic>;
                    bool isMe = message['senderEmail'] == _user?.email;

                    // Since this is the Leader app, the leader can see ALL messages
                    // except maybe "Host Only" messages not intended for them, but they are the host.

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[400] : (message['recipient'] == "Host Only" ? Colors.orange[200] : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${message['senderName']} (${message['recipient']})",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isMe ? Colors.white : Colors.black87),
                            ),
                            SizedBox(height: 3),
                            Text(
                              message['text'] ?? "",
                              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      fillColor: Colors.grey[200],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () async {
                    if (_messageController.text.trim().isNotEmpty && _user != null) {
                      String text = _messageController.text.trim();
                      _messageController.clear(); // Clear immediately for UX

                      await _firestore.collection("events").doc(widget.eventCode).collection("chats").add({
                        'text': text,
                        'senderId': _user!.uid,
                        'senderEmail': _user!.email,
                        'senderName': _username,
                        'senderRole': 'leader',
                        'recipient': selectedRecipient,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

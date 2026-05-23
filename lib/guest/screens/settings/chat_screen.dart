
//chat_screen.dart


import 'package:flutter/material.dart';
import '../guest_dashboard.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String selectedRecipient = "Everyone"; // Default recipient
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];

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
                MaterialPageRoute(builder: (context) => GuestDashboard()),
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
                  items: ["Everyone", "Leader", "Members"]
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
            child: ListView.builder(
              controller: _scrollController, // Attach the scroll controller
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isMe = message['sender'] == "Me";

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[400] : Colors.grey[300],
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
                          "${message['sender']} (${message['recipient']})",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                        ),
                        SizedBox(height: 3),
                        Text(
                          message['text'] ?? "",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
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
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      setState(() {
                        messages.add({
                          'sender': "Me",
                          'recipient': selectedRecipient,
                          'text': _messageController.text,
                        });
                      });
                      _messageController.clear();

                      // Auto-scroll to the latest message
                      Future.delayed(Duration(milliseconds: 300), () {
                        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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

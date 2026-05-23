//forgot_eventcode.dart

import 'package:flutter/material.dart';
import '../dashboard/home_page.dart';

class ForgotEventCode extends StatefulWidget {
  @override
  _ForgotEventCodeState createState() => _ForgotEventCodeState();
}

class _ForgotEventCodeState extends State<ForgotEventCode> {
  final TextEditingController _emailController = TextEditingController();

  void _sendEventCode() {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your email address")),
      );
      return;
    }

    // Here, you would add actual backend functionality to send the event code via email.
    // For now, just showing a confirmation message.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Event code sent to $email")),
    );

    // Redirect to home_page.dart after showing the message
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Recover Event Code")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter your registered email", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendEventCode,
                child: Text("Recover Event Code"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

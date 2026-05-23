

//signup_4_review.dart


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dashboard/home_page.dart';
import '../services/auth_service.dart';  // Authentication service
import '../services/firestore_service.dart';  // Firestore service
import 'dart:math';

class SignupReview extends StatelessWidget {
  final String eventTitle;
  final String eventDescription;
  final String eventCategory;
  final String eventType;
  final String ageLimit;
  final String? eventImage;
  final String eventLocation;
  final double? eventLatitude;
  final double? eventLongitude;

  const SignupReview({
    required this.eventTitle,
    required this.eventDescription,
    required this.eventCategory,
    required this.eventType,
    required this.ageLimit,
    this.eventImage,
    required this.eventLocation,
    this.eventLatitude,
    this.eventLongitude,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review Your Event"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Review Event Details",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Please review the information you provided for your event. You can edit the details if needed.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              // Event Logo/Image Preview
              if (eventImage != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: AssetImage(eventImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text("No event image added")),
                ),
              SizedBox(height: 20),

              // Event Details
              _reviewItem("Event Title", eventTitle),
              _reviewItem("Event Description", eventDescription),
              _reviewItem("Event Category", eventCategory),
              _reviewItem("Event Type", eventType),
              _reviewItem("Age Limit", ageLimit),
              _reviewItem("Location", eventLocation),
              if (eventLatitude != null && eventLongitude != null)
                _reviewItem(
                  "Coordinates",
                  "Lat: ${eventLatitude!.toStringAsFixed(6)}, Lng: ${eventLongitude!.toStringAsFixed(6)}",
                ),

              SizedBox(height: 30),

              // Submit Button
              ElevatedButton.icon(
                onPressed: () => _submitEvent(context),
                icon: Icon(Icons.check),
                label: Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for displaying review items
  Widget _reviewItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
        Divider(height: 30, thickness: 1),
      ],
    );
  }

  // Function to store event details in Firestore
  void _submitEvent(BuildContext context) async {
    try {
      String? UID = AuthService().getCurrentUserId(); // Get current leader's UID
      String? userEmail = AuthService().getCurrentMail(); // Get current leader's email

      if (userEmail == null) {
        _showErrorDialog(context, "User not found. Please log in again.");
        return;
      }

      // Prepare event data
      String generateEventCode(String eventTitle) {
        // Take first 5 letters (uppercase), remove spaces
        String prefix = eventTitle.replaceAll(" ", "").toUpperCase().substring(0, min(5, eventTitle.length));

        // Generate last 5 digits from timestamp (milliseconds) to ensure uniqueness
        String timePart = DateTime.now().millisecondsSinceEpoch.toString().substring(8);

        return "$prefix-$timePart";
      }


      String eventCode = generateEventCode(eventTitle);

      Map<String, dynamic> eventData = {
        "title": eventTitle,
        "eventCode": eventCode,
        "isApproved": false,
        "description": eventDescription,
        "category": eventCategory,
        "type": eventType,
        "ageLimit": ageLimit,
        "image": eventImage ?? "",
        "location": eventLocation,
        "latitude": eventLatitude,
        "longitude": eventLongitude,
        "createdBy": userEmail,
        "createdByID": UID,
        "timestamp": FieldValue.serverTimestamp(),
      };

      // Save event under the logged-in leader's collection (keyed by email)
      await FirestoreService().saveEvent(userEmail, eventData, eventCode);

      // Show confirmation with event code
      _showConfirmationDialog(context, eventCode);
    } catch (e) {
      _showErrorDialog(context, "Failed to submit event. Try again.");
    }
  }

  // Function to show the confirmation dialog with event code + copy button
  void _showConfirmationDialog(BuildContext context, String eventCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text("Event Submitted"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Event details have been accepted, and approval has been sent to your email address.",
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 20),
              Text(
                "Your Event Code:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        eventCode,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.indigo),
                      tooltip: "Copy Event Code",
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: eventCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Event code copied to clipboard!"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                "⚠️ Save this code! You'll need it to log in and manage your event.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                    (route) => false,
                ); // Navigate to HomePage
              },
              child: Text("Return to Home Page"),
            ),
          ],
        );
      },
    );
  }

  // Function to show error message
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}

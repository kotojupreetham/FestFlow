//signup_1_how_to_nominate.dart

import 'package:flutter/material.dart';
import 'signup_2_choose_location.dart';

class SignupHowToNominate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Event Nomination Guide"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Heading with icon
              Row(
                children: [
                  Icon(Icons.event_available, color: Colors.indigo, size: 32),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "How to Nominate an Event",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "Follow these steps to successfully nominate your event:",
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),

              // Steps — numbered cards
              Expanded(
                child: ListView(
                  children: [
                    _buildStepCard(
                      stepNumber: 1,
                      icon: Icons.place,
                      iconColor: Colors.green,
                      title: "Choose Location",
                      description: "Pick an appropriate and accessible event location using GPS or manual entry.",
                    ),
                    _buildStepCard(
                      stepNumber: 2,
                      icon: Icons.title,
                      iconColor: Colors.blue,
                      title: "Event Title",
                      description: "Provide a clear and descriptive event title that represents your fest.",
                    ),
                    _buildStepCard(
                      stepNumber: 3,
                      icon: Icons.image,
                      iconColor: Colors.orange,
                      title: "Upload Image",
                      description: "Upload a relevant event logo or banner picture for visibility.",
                    ),
                    _buildStepCard(
                      stepNumber: 4,
                      icon: Icons.category,
                      iconColor: Colors.purple,
                      title: "Set Category",
                      description: "Ensure the event category accurately matches its purpose.",
                    ),

                    SizedBox(height: 24),

                    // Failure section header
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Cases That May Cause Rejection",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),

                    _buildFailureItem(
                      icon: Icons.location_off,
                      text: "The event location is invalid or inaccessible.",
                    ),
                    _buildFailureItem(
                      icon: Icons.description,
                      text: "The event description is incomplete or unclear.",
                    ),
                    _buildFailureItem(
                      icon: Icons.broken_image,
                      text: "The uploaded image is irrelevant or inappropriate.",
                    ),
                    _buildFailureItem(
                      icon: Icons.warning,
                      text: "The event category is incorrect or missing.",
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // Navigation Button — full width
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignupChooseLocation(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Get Started", style: TextStyle(fontSize: 17)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Numbered step card
  Widget _buildStepCard({
    required int stepNumber,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              "$stepNumber",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: iconColor,
              ),
            ),
          ),
          SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Failure list item — compact
  Widget _buildFailureItem({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.red, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }
}

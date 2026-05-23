//signup_3_describe_event.dart

import 'package:flutter/material.dart';
import 'signup_4_review.dart';

class SignupDescribeEvent extends StatefulWidget {
  final String eventLocation;
  final double? eventLatitude;
  final double? eventLongitude;

  const SignupDescribeEvent({
    Key? key,
    required this.eventLocation,
    this.eventLatitude,
    this.eventLongitude,
  }) : super(key: key);

  @override
  _SignupDescribeEventState createState() => _SignupDescribeEventState();
}

class _SignupDescribeEventState extends State<SignupDescribeEvent> {
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedEventType;
  String? _selectedAgeLimit;
  List<String> _categories = ["Conference", "Workshop", "Party", "Festival", "Other"];
  List<String> _eventTypes = ["Private", "Public", "Other"];
  List<String> _ageLimits = ["Under 18", "Under 21", "Other"];
  TextEditingController _customCategoryController = TextEditingController();
  TextEditingController _customEventTypeController = TextEditingController();
  TextEditingController _customAgeLimitController = TextEditingController();
  String? _imagePath; // Placeholder for image upload

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Describe Your Event")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add Event Details",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Provide information about your event, including a title, description, category, and image/logo.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              // Event Logo/Image Picker
              GestureDetector(
                onTap: () {
                  // TODO: Add image picker functionality
                  setState(() {
                    _imagePath = "assets/placeholder.png"; // Temporary placeholder
                  });
                },
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                  ),
                  child: _imagePath == null
                      ? Center(child: Text("Tap to upload an event logo/image"))
                      : Image.asset(_imagePath!, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 20),

              // Event Title Input
              TextField(
                controller: _eventTitleController,
                decoration: InputDecoration(
                  labelText: "Event Title",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),

              // Event Description Input
              TextField(
                controller: _eventDescriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Event Description",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),

              // Event Category Dropdown with Custom Option
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: Text("Select Event Category"),
                items: _categories
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              if (_selectedCategory == "Other")
                TextField(
                  controller: _customCategoryController,
                  decoration: InputDecoration(
                    labelText: "Enter Custom Category",
                    border: OutlineInputBorder(),
                  ),
                ),
              SizedBox(height: 20),

              // Event Type Dropdown with Custom Option
              DropdownButtonFormField<String>(
                value: _selectedEventType,
                hint: Text("Select Event Type"),
                items: _eventTypes
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              if (_selectedEventType == "Other")
                TextField(
                  controller: _customEventTypeController,
                  decoration: InputDecoration(
                    labelText: "Enter Custom Event Type",
                    border: OutlineInputBorder(),
                  ),
                ),
              SizedBox(height: 20),

              // Age Limit Dropdown with Custom Option
              DropdownButtonFormField<String>(
                value: _selectedAgeLimit,
                hint: Text("Select Age Limit"),
                items: _ageLimits
                    .map((limit) => DropdownMenuItem(
                  value: limit,
                  child: Text(limit),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAgeLimit = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              if (_selectedAgeLimit == "Other")

                TextField(
                  controller: _customAgeLimitController,
                  decoration: InputDecoration(
                    labelText: "Enter Custom Age Limit",
                    border: OutlineInputBorder(),
                  ),
                ),
              SizedBox(height: 30),

              // Next Button
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {
                    // Validate inputs before navigating
                    if (_eventTitleController.text.isNotEmpty &&
                        _eventDescriptionController.text.isNotEmpty &&
                        _selectedCategory != null &&
                        _selectedEventType != null &&
                        _selectedAgeLimit != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignupReview(
                            eventTitle: _eventTitleController.text,
                            eventDescription: _eventDescriptionController.text,
                            eventCategory: _selectedCategory == "Other"
                                ? _customCategoryController.text
                                : _selectedCategory!,
                            eventType: _selectedEventType == "Other"
                                ? _customEventTypeController.text
                                : _selectedEventType!,
                            ageLimit: _selectedAgeLimit == "Other"
                                ? _customAgeLimitController.text
                                : _selectedAgeLimit!,
                            eventImage: _imagePath,
                            eventLocation: widget.eventLocation,
                            eventLatitude: widget.eventLatitude,
                            eventLongitude: widget.eventLongitude,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please fill in all fields")),
                      );
                    }
                  },
                  child: Text("Next"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//help.dart

import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _hostTabController;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _hostTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _hostTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
        backgroundColor: Color.fromARGB(255, 251, 101, 66),
      ),
      body: Column(
        children: [
          // Main Tab Bar (Host, Guest)
          Container(
            color: Color.fromARGB(255, 251, 101, 66),
            child: TabBar(
              controller: _mainTabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              indicatorColor: Colors.white,
              indicatorWeight: 4.0,
              tabs: [
                Tab(text: 'Host'),
                Tab(text: 'Guest'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                // Host Tab Content
                Column(
                  children: [
                    // Sub Tab Bar (Leader, Member)
                    TabBar(
                      controller: _hostTabController,
                      labelColor: Colors.black,
                      indicatorColor: Color.fromARGB(255, 251, 101, 66),
                      indicatorWeight: 4.0,
                      tabs: [
                        Tab(text: 'Leader'),
                        Tab(text: 'Member'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _hostTabController,
                        children: [
                          // Leader Content
                          _buildLeaderContent(),
                          // Member Content
                          _buildMemberContent(),
                        ],
                      ),
                    ),
                  ],
                ),
                // Guest Tab Content
                _buildGuestContent(),
              ],
            ),
          ),
          // Common Information at the Bottom
          SizedBox(height: 20),
          _buildCommonInfoSection(),
        ],
      ),
    );
  }

  // Content for Guest
  Widget _buildGuestContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Features for Guests'),
          SizedBox(height: 10),
          _buildBulletPoint('Enter the Event Code to access event details after logging in with Gmail and phone number.'),
          _buildBulletPoint('Explore event schedule, programs, venue location, and more.'),
          _buildBulletPoint('Purchase tickets securely and check-in using a QR code.'),
          _buildBulletPoint('Provide feedback to help organizers improve future events.'),
          _buildBulletPoint('Stay updated with real-time notifications.'),
        ],
      ),
    );
  }

  // Content for Leader
  Widget _buildLeaderContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Features for Leaders'),
          SizedBox(height: 10),
          _buildBulletPoint('Create and manage events by providing details such as name, location, and theme.'),
          _buildBulletPoint('Define programs, assign roles, and oversee program details.'),
          _buildBulletPoint('Use the chat feature for private and team communication.'),
          _buildBulletPoint('Access event analytics like attendance metrics, revenue, and feedback.'),
          _buildBulletPoint('Send real-time updates to team members and guests.'),
        ],
      ),
    );
  }

  // Content for Member
  Widget _buildMemberContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Features for Members'),
          SizedBox(height: 10),
          _buildBulletPoint('Add and update program details, including schedules and ticket prices.'),
          _buildBulletPoint('Communicate with the team using the chat feature for quick issue resolution.'),
          _buildBulletPoint('Receive notifications about event changes and updates.'),
          _buildBulletPoint('Collaborate with the Leader to maintain program quality and implement feedback.'),
        ],
      ),
    );
  }

  // Helper Method to Build Bullet Points
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 18, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  // Common Information Section (FAQ and Contact)
  Widget _buildCommonInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildSectionTitle('Frequently Asked Questions'),
          SizedBox(height: 10),
          _buildCommonBulletPoint('How do I log in as a Guest?'),
          _buildCommonBulletPoint('How do I create an event as a Host?'),
          _buildCommonBulletPoint('What is the QR code check-in system?'),
          SizedBox(height: 20),
          _buildSectionTitle('Need Further Assistance?'),
          SizedBox(height: 10),
          _buildContactRow(Icons.email, 'support@festflow.com'),
          SizedBox(height: 10),
          _buildContactRow(Icons.phone, '+1 800-123-4567'),
        ],
      ),
    );
  }

  // Helper Method to Build Section Titles
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Icon(Icons.help_outline, color: Colors.blue),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }

  // Helper Method to Build Common Bullet Points
  Widget _buildCommonBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check, size: 18, color: Colors.green),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  // Helper Method to Build Contact Row
  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),
        SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.grey[800]),
        ),
      ],
    );
  }
}
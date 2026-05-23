//home_page.dart

import 'package:flutter/material.dart';
import 'host_zone.dart';
import 'guest_zone.dart';
import '../help/help.dart';

class HomePage extends StatelessWidget {
  // This function is triggered when the help button is pressed
  void _navigateToHelp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HelpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Welcome to FestFlow'),
        backgroundColor: Color.fromARGB(255, 251, 101, 66),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Host Zone Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HostZonePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 55, 94, 151),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                'Host Zone',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(height: 20), // Space between buttons
            // Guest Zone Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GuestZonePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 255, 187, 0),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                'Guest Zone',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToHelp(context),
        child: Icon(Icons.help),
        backgroundColor: Color.fromARGB(255, 251, 101, 66),
      ),
    );
  }
}

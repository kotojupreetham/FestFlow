//face_page.dart
//face_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dashboard/home_page.dart';
import '../leader/screens/leader_dashboard.dart';
import '../member/screens/member_dashboard.dart';
import 'package:festflow/global.dart';
import '../guest/screens/guest_dashboard.dart';
import 'widgets/loading_bar.dart';
import 'widgets/logo_with_name.dart';
import 'dashboard/all_event_list.dart';

class FacePage extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  // Check if user is already logged in and eligible for auto-login
  Future<void> _checkAutoLogin() async {
    try {
      // await GoogleSignIn().signOut();
      // await FirebaseAuth.instance.signOut();

      User? user = _auth.currentUser;
      if (user == null) {
        print("No user found. Navigating to Home.");
        _navigateToHome();
        return;
      }


      // Fetch user events to determine role and active event
      String docId = user.email!;
      QuerySnapshot eventsSnapshot = await _firestore.collection('users').doc(docId).collection('events').get();

      String role = '';
      String eventCode = '';

      if (eventsSnapshot.docs.isNotEmpty) {
        // Fallback to the first joined event for auto-login
        var firstEvent = eventsSnapshot.docs.first;
        eventCode = firstEvent.id;
        
        Map<String, dynamic> eventData = firstEvent.data() as Map<String, dynamic>;
        role = eventData.containsKey('role') ? eventData['role'] : '';
        
        // Expose isApproved for Guests
        if (role == 'guest') {
          bool isGuestApproved = eventData['isApproved'] == true;
          if (isGuestApproved) {
            role = 'guest_approved';
          } else {
            role = 'guest_pending';
          }
        }
      }

      if (eventCode.isEmpty) {
        _navigateToHome();
        return;
      }

      // Assign to Global State
      GlobalState.activeEventCode = eventCode;

      print("User Role: $role, Event Code: $eventCode");

      if (role == 'leader' && eventCode.isNotEmpty) {
        DocumentSnapshot eventDoc =
        await _firestore.collection('events').doc(eventCode).get();

        print(
            "Event Doc Exists: ${eventDoc
                .exists}, isApproved: ${eventDoc['isApproved']}");

        if (eventDoc.exists && eventDoc['isApproved'] == true) {
          print("Navigating to Leader Dashboard...");
          Future.delayed(Duration(seconds: 3), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LeaderDashboard()),
            );
          });
          return;
        }
      }
      if (role == 'member' && eventCode.isNotEmpty) {
        DocumentSnapshot eventDoc =
        await _firestore.collection('events').doc(eventCode).get();

        print(
            "Event Doc Exists: ${eventDoc
                .exists}, isApproved: ${eventDoc['isApproved']}");

        if (eventDoc.exists && eventDoc['isApproved'] == true) {
          print("Navigating to Member Dashboard...");
          Future.delayed(Duration(seconds: 3), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MemberDashboard()),
            );
          });
          return;
        }
      }
      if (role == 'guest_approved' && eventCode.isNotEmpty) {
        print("Navigating to Guest Dashboard...");

        Future.delayed(Duration(seconds: 3), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => GuestDashboard()),
          );
        });
        return;
      }

      if (role == 'guest_pending' && eventCode.isNotEmpty) {
        print("Guest waiting for approval... Navigating to All Events...");

        Future.delayed(Duration(seconds: 3), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AllEventList()),
          );
        });
        return;
      }

      print("Conditions not met. Navigating to Home.");
      _navigateToHome();
    }catch (e) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        // MaterialPageRoute(builder: (context) => GuestDashboard()),
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /*LogoWithName(
              logoPath: 'assets/images/logo.png',
              appName: 'FestFlow',
              textStyle: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),*/
            Text(
              'FestFlow',
              style: TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'The Streamlined Way to Manage Events',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 50),
            LoadingBar(size: 50, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}

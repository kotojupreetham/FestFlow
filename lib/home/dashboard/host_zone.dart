
//host_zone.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../help/help.dart';
import '../auth/leader_signup.dart';
import '../auth/forgot_eventcode.dart';
import '../auth/member_signup.dart';
import '../../leader/screens/leader_dashboard.dart';
import '../../member/screens/member_dashboard.dart';
import 'package:festflow/global.dart';

class HostZonePage extends StatefulWidget {
  @override
  _HostZonePageState createState() => _HostZonePageState();
}

class _HostZonePageState extends State<HostZonePage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _eventCodeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userRole;
  User? _currentUser;

  Future<void> _signInWithGoogle() async {
    if (_userRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a role before signing in.")),
      );
      return;
    }

    User? user = await _authService.signInWithGoogle(_userRole!);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed or account not found")),
      );
      return;
    }
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _validateEventCode() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please sign in first.")),
      );
      return;
    }

    String eventCode = _eventCodeController.text.trim();
    if (eventCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter an event code.")),
      );
      return;
    }

    if (_userRole == 'leader') {
      bool isValid = await _firestoreService.validateUserEventCode(
          _currentUser!.email!, eventCode);
      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid Event Code.")),
        );
        return;
      }

      bool isApproved = await _firestoreService.isEventApproved(_currentUser!.email!, eventCode);
      if (!isApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Event is not approved yet.")),
        );
        return;
      }
    }
    /*if (_userRole == 'leader') {
      await _firestoreService.saveEventCode(eventCode);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LeaderDashboard()),
      );
    }*/
    if (_userRole == 'leader') {
      try {
        DocumentSnapshot eventSnapshot =
        await _firestore.collection("events").doc(eventCode).get();

        if (eventSnapshot.exists) {
          // If event exists, navigate to Leader Dashboard
          GlobalState.activeEventCode = eventCode;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LeaderDashboard()),
          );
        } else {
          // Fetch eventData from signup_4_review.dart (pass this when calling _validateEventCode)


          // Create event structure
          await _firestoreService.createEventStructure(
              eventCode, _currentUser!.email!);

          // Navigate to Leader Dashboard after creating event structure
          GlobalState.activeEventCode = eventCode;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LeaderDashboard()),
          );
        }
      } catch (e) {
        print("Error validating event code: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed to validate event code. Please try again.")),
        );
      }
    }else if (_userRole == 'member') {
      try {
        String memberEmail = _currentUser!.email!;

        // Check if member has been invited
        Map<String, dynamic>? invitation =
            await _firestoreService.checkMemberInvitation(memberEmail, eventCode);

        if (invitation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("You haven't been invited to this event.")),
          );
          return;
        }

        if (invitation["isJoined"] == true) {
          // Already joined
          GlobalState.activeEventCode = eventCode;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MemberDashboard()),
          );
        } else {
          // Accept invitation
          await _firestoreService.joinEventAsMember(
            memberEmail,
            _currentUser!.displayName ?? "Member",
            _currentUser!.uid,
            eventCode,
          );

          GlobalState.activeEventCode = eventCode;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MemberDashboard()),
          );
        }
      } catch (e) {
        print("Error handling member event code: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to join event. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Host Zone Sign In'),
        backgroundColor: Color.fromARGB(255, 55, 94, 151),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('leader', style: TextStyle(fontSize: 12)),
                  Radio<String>(
                    value: 'leader',
                    groupValue: _userRole,
                    onChanged: (String? value) {
                      setState(() => _userRole = value);
                    },
                  ),
                  Text('Member', style: TextStyle(fontSize: 12)),
                  Radio<String>(
                    value: 'member',
                    groupValue: _userRole,
                    onChanged: (String? value) {
                      setState(() => _userRole = value);
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _signInWithGoogle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login),
                    SizedBox(width: 10),
                    Text("Continue with Google"),
                  ],
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _eventCodeController,
                decoration: InputDecoration(
                  labelText: 'Event Code',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _validateEventCode,
                child: Text("Validate Event Code"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextButton(
                    onPressed: _userRole == 'leader'
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ForgotEventCode()),
                            )
                        : null,
                    child: Text('Forgot Event Code?'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: _userRole == 'leader'
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LeaderSignup()),
                        )
                    : _userRole == 'member'
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MemberSignup()),
                            )
                        : null,
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HelpPage()),
        ),
        child: Icon(Icons.help),
        backgroundColor: Color.fromARGB(255, 55, 94, 151),
      ),
    );
  }
}

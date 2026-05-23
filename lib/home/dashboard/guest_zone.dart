import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'all_event_list.dart';
import '../auth/guest_signup.dart';
import '../help/help.dart';

class GuestZonePage extends StatefulWidget {
  @override
  _GuestZonePageState createState() => _GuestZonePageState();
}

class _GuestZonePageState extends State<GuestZonePage> {
  final AuthService _authService = AuthService();
  User? _currentUser;

  Future<void> _signInWithGoogle() async {
    User? user = await _authService.signInWithGoogle("guest");

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed")),
      );
      return;
    }

    setState(() => _currentUser = user);
    print("done");
    // Redirect to the all events page after login
    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(builder: (context) => AllEventList()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guest Zone Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton.icon(
                icon: Icon(Icons.login),
                label: Text("Continue with Google"),
                onPressed: _signInWithGoogle,
              ),

              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GuestSignup()),
                ),
                child: Text('Sign Up'),
              )
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

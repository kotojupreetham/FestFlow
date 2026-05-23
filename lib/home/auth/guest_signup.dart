//leader_signup.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../dashboard/home_page.dart';

class GuestSignup extends StatefulWidget {
  @override
  _GuestSignupState createState() => _GuestSignupState();
}

class _GuestSignupState extends State<GuestSignup> {
  //final TextEditingController _emailController = TextEditingController()
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  /// Handle Google Sign-In
  Future<void> _signInWithGoogle() async {
    final userCredential = await _authService.signUpWithGoogle();
    if (userCredential?.user != null) {
      _promptForUsername(userCredential!.user!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed")),
      );
    }
  }

  /// Prompt user for a username
  void _promptForUsername(User user) {
    TextEditingController usernameController = TextEditingController();
    bool isSaving = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Choose a Username"),
              content: TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  hintText: "Enter your username",
                  errorText: errorMessage,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    String username = usernameController.text.trim();
                    if (username.isEmpty) {
                      setState(() => errorMessage = "Username cannot be empty");
                      return;
                    }

                    setState(() {
                      isSaving = true;
                      errorMessage = null;
                    });

                    try {
                      bool isTaken = await _firestoreService.isUsernameTaken(username);
                      if (isTaken) {
                        setState(() {
                          errorMessage = "Username is already taken. Try another.";
                          isSaving = false;
                        });
                        return;
                      }

                      await _firestoreService.saveUserProfile(
                          user.uid, user.email!, username);

                      Navigator.pop(context); // Close dialog
                      _navigateToNextScreen();
                    } catch (e) {
                      setState(() => errorMessage = "Error: $e");
                    } finally {
                      setState(() => isSaving = false);
                    }
                  },
                  child: isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Continue"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Navigate to the next signup screen
  void _navigateToNextScreen() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Guest Signup")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*Text("Create an Account", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: "Enter Email Address"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String email = _emailController.text.trim();

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter an email address")),
                  );
                  return;
                }

                bool otpSent = await AuthService().sendOtp(email);

                if (otpSent) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtpVerification(email: email, isForgotPassword: false),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to send OTP. Try again.")),
                  );
                }
              },
              child: Text("Continue"),
            ),
            SizedBox(height: 10),
            Center(child: Text("Or")),
            SizedBox(height: 10),

             */
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
          ],
        ),
      ),
    );
  }
}

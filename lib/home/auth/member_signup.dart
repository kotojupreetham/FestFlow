//member_signup.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../dashboard/home_page.dart';

class MemberSignup extends StatefulWidget {
  @override
  _MemberSignupState createState() => _MemberSignupState();
}

class _MemberSignupState extends State<MemberSignup> {
  //final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  /// Handle Google Sign-In
  Future<void> _ContinueWithGoogle() async {
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
      appBar: AppBar(title: Text("Member Signup")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            ElevatedButton(
              onPressed: _ContinueWithGoogle,
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

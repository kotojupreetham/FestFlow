
//auth_service.dart

//Handles Firebase Authentication (Google Sign-In, OTP, etc.)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // **Sign In with Email & Password**
  Future<User?> signInWithGoogle(String userRole) async {
    try {
      await GoogleSignIn().signOut();  // Ensures account selection every time
      await FirebaseAuth.instance.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google Sign-In cancelled by user.");
        return null;
      }

      print("Google Sign-In Success: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user == null) {
        print("FirebaseAuth returned null user.");
        return null;
      }

      print("FirebaseAuth Success: ${user.email}, UID: ${user.uid}");

      // Determine which collection to check based on selected role
      // leader → leader/{email}, member → users/{email}
      String collection = userRole.toLowerCase() == 'leader' ? 'leader' : 'users';
      String docId = user.email!;

      DocumentSnapshot userDoc = await _firestore.collection(collection).doc(docId).get();

      if (!userDoc.exists) {
        print("Firestore: No document found for $docId in $collection.");
        throw Exception("Account not found under this role.");
      }

      print("User found in Firestore ($collection): ${userDoc.data()}");
      return user;
    } catch (e) {
      print("Google Sign-In failed: $e");
      return null;
    }
  }

  // Sign in with Email and Password
  Future<UserCredential?> signUpWithGoogle() async {
    try {

      await GoogleSignIn().signOut();  // Ensures account selection every time
      await FirebaseAuth.instance.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      if (googleAuth == null) return null;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign-In  failed: $e");
      return null;
    }
  }



  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  String? getCurrentMail() {
    return _auth.currentUser?.email;
  }
}


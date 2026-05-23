//firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ──────────────────────────────────────────────
  // LEADER METHODS (leader/{email} collection)
  // ──────────────────────────────────────────────

  /// Save leader details to leader/{email}
  Future<void> saveUserDetails(
      String uid, String email, String username) async {
    try {
      await _firestore.collection("leader").doc(email).set({
        "email": email,
        "username": username,
        "uid": uid,
        "createdAt": FieldValue.serverTimestamp(),
      });
      print("Leader details saved successfully");
    } catch (e) {
      print("Error saving leader details: $e");
      throw Exception("Failed to save leader details");
    }
  }

  /// Save event details under leader/{email}/events/{eventCode}
  Future<void> saveEvent(
      String userEmail, Map<String, dynamic> eventData, String eventCode) async {
    try {
      await _firestore
          .collection("leader")
          .doc(userEmail)
          .collection("events")
          .doc(eventCode)
          .set(eventData);

      print("Event saved successfully for leader: $userEmail");
    } catch (e) {
      print("Error saving event: $e");
      throw Exception("Failed to save event");
    }
  }

  /// Check if leader's event code exists in leader/{email}/events/{eventCode}
  Future<bool> validateUserEventCode(String userEmail, String eventCode) async {
    try {
      DocumentSnapshot eventDoc = await _firestore
          .collection("leader")
          .doc(userEmail)
          .collection("events")
          .doc(eventCode)
          .get();

      if (eventDoc.exists) {
        print("Event code found for leader!");
        return true;
      } else {
        print("Event code not found for leader.");
        return false;
      }
    } catch (e) {
      print("Error validating event code: $e");
      return false;
    }
  }

  /// Check if the event is approved (direct lookup in leader collection)
  Future<bool> isEventApproved(String userEmail, String eventCode) async {
    try {
      DocumentSnapshot eventDoc = await _firestore
          .collection("leader")
          .doc(userEmail)
          .collection("events")
          .doc(eventCode)
          .get();

      if (eventDoc.exists && eventDoc["isApproved"] == true) {
        print("Event is approved.");
        return true;
      }

      print("Event not approved or not found.");
      return false;
    } catch (e) {
      print("Error checking event approval: $e");
      return false;
    }
  }

  /// Create event structure in events/{eventCode} from leader data
  Future<void> createEventStructure(String eventCode, String leaderEmail) async {
    try {
      DocumentReference eventRef =
          _firestore.collection("events").doc(eventCode);
      DocumentReference leaderRef = _firestore.collection("leader").doc(leaderEmail);

      // Read event data from leader/{email}/events/{eventCode}
      DocumentSnapshot eventDataSnapshot =
          await leaderRef.collection("events").doc(eventCode).get();
      Map<String, dynamic> eventData = eventDataSnapshot.exists
          ? eventDataSnapshot.data() as Map<String, dynamic>
          : {};

      // Read leader profile data from leader/{email}
      DocumentSnapshot leaderDocSnapshot = await leaderRef.get();
      Map<String, dynamic> leaderData = leaderDocSnapshot.exists
          ? leaderDocSnapshot.data() as Map<String, dynamic>
          : {};

      // Create main event document with details and leader as map fields
      await eventRef.set({
        "createdAt": FieldValue.serverTimestamp(),
        "isApproved": true,
        "signAt": FieldValue.serverTimestamp(),
        "details": eventData,
        "leader": leaderData,
      });

      // Initialize empty subcollections
      await eventRef.collection("member").doc("init").set({});
      await eventRef.collection("guest").doc("init").set({});
      await eventRef.collection("Guest").doc("init").set({});
      await eventRef.collection("sub-events").doc("init").set({});
      await eventRef.collection("chat").doc("init").set({});
      await eventRef.collection("notification").doc("init").set({});
      await eventRef.collection("permissions").doc("init").set({});

      print("Event structure created successfully!");
    } catch (e) {
      print("Error creating event structure: $e");
      throw Exception("Failed to create event structure");
    }
  }

  // ──────────────────────────────────────────────
  // USERS METHODS (users/{email} — members & guests)
  // ──────────────────────────────────────────────

  /// Save member/guest profile to users/{email}
  Future<void> saveUserProfile(
      String uid, String email, String username) async {
    try {
      await _firestore.collection("users").doc(email).set({
        "email": email,
        "username": username,
        "uid": uid,
        "createdAt": FieldValue.serverTimestamp(),
      });
      print("User profile saved successfully");
    } catch (e) {
      print("Error saving user profile: $e");
      throw Exception("Failed to save user profile");
    }
  }

  /// Member accepts invitation:
  /// 1. Update events/{eventCode}/member/{email} → isJoined=true + user data
  /// 2. Add users/{email}/events/{eventCode} → role="member"
  Future<void> joinEventAsMember(
      String email, String username, String uid, String eventCode) async {
    try {
      // Get event title for caching in user's events list
      DocumentSnapshot eventDoc = await _firestore
          .collection("events")
          .doc(eventCode)
          .get();
      String eventTitle = "";
      if (eventDoc.exists) {
        Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
        if (data.containsKey("details") && data["details"] != null) {
          eventTitle = data["details"]["title"] ?? "";
        }
      }

      // Update events/{eventCode}/member/{email} → mark as joined
      await _firestore
          .collection("events")
          .doc(eventCode)
          .collection("member")
          .doc(email)
          .update({
        "isJoined": true,
        "username": username,
        "uid": uid,
      });

      // Add users/{email}/events/{eventCode} → track participation
      await _firestore
          .collection("users")
          .doc(email)
          .collection("events")
          .doc(eventCode)
          .set({
        "role": "member",
        "eventCode": eventCode,
        "eventTitle": eventTitle,
        "joinedAt": FieldValue.serverTimestamp(),
      });

      print("Member joined event successfully!");
    } catch (e) {
      print("Error joining event as member: $e");
      throw Exception("Failed to join event as member");
    }
  }

  /// Guest joins event:
  /// 1. Add events/{eventCode}/Guest/{email}
  /// 2. Add users/{email}/events/{eventCode} → role="guest"
  Future<void> joinEventAsGuest(
      String email, String username, String uid, String eventCode) async {
    try {
      // Get event title for caching
      DocumentSnapshot eventDoc = await _firestore
          .collection("events")
          .doc(eventCode)
          .get();
      String eventTitle = "";
      if (eventDoc.exists) {
        Map<String, dynamic> data = eventDoc.data() as Map<String, dynamic>;
        if (data.containsKey("details") && data["details"] != null) {
          eventTitle = data["details"]["title"] ?? "";
        }
      }

      // Add events/{eventCode}/Guest/{email}
      await _firestore
          .collection("events")
          .doc(eventCode)
          .collection("Guest")
          .doc(email)
          .set({
        "email": email,
        "username": username,
        "uid": uid,
        "joinedAt": FieldValue.serverTimestamp(),
      });

      // Add users/{email}/events/{eventCode}
      await _firestore
          .collection("users")
          .doc(email)
          .collection("events")
          .doc(eventCode)
          .set({
        "role": "guest",
        "eventCode": eventCode,
        "eventTitle": eventTitle,
        "joinedAt": FieldValue.serverTimestamp(),
      });

      print("Guest joined event successfully!");
    } catch (e) {
      print("Error joining event as guest: $e");
      throw Exception("Failed to join event as guest");
    }
  }

  /// Get all events a user participates in (members & guests)
  Future<List<Map<String, dynamic>>> getUserEvents(String email) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection("users")
          .doc(email)
          .collection("events")
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data["eventCode"] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching user events: $e");
      return [];
    }
  }

  /// Check if a member has been invited to an event
  Future<Map<String, dynamic>?> checkMemberInvitation(
      String email, String eventCode) async {
    try {
      DocumentSnapshot memberDoc = await _firestore
          .collection("events")
          .doc(eventCode)
          .collection("member")
          .doc(email)
          .get();

      if (memberDoc.exists) {
        return memberDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error checking member invitation: $e");
      return null;
    }
  }

  // ──────────────────────────────────────────────
  // SHARED METHODS
  // ──────────────────────────────────────────────

  /// Check if username already exists in BOTH leader and users collections
  Future<bool> isUsernameTaken(String username) async {
    try {
      // Check leader collection
      QuerySnapshot leaderQuery = await _firestore
          .collection("leader")
          .where("username", isEqualTo: username)
          .get();
      if (leaderQuery.docs.isNotEmpty) return true;

      // Check users collection
      QuerySnapshot usersQuery = await _firestore
          .collection("users")
          .where("username", isEqualTo: username)
          .get();
      if (usersQuery.docs.isNotEmpty) return true;

      return false;
    } catch (e) {
      print("Error checking username availability: $e");
      return false;
    }
  }

  /// Check if events/{eventCode} exists in root collection
  Future<bool> doesEventExist(String eventCode) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection("events")
          .doc(eventCode)
          .get();
      return doc.exists;
    } catch (e) {
      print("Error checking event existence: $e");
      return false;
    }
  }

  /// Save event code to events collection (legacy — kept for compatibility)
  Future<void> saveEventCode(String eventCode) async {
    try {
      await _firestore.collection("events").doc(eventCode).set({
        "signAt": FieldValue.serverTimestamp(),
        "isApproved": true,
      });
    } catch (e) {
      print("Error saving event code: $e");
      throw Exception("Failed to save event code");
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Login Error: ${e.message}");
      return null;
    }
  }

  // Register with email, password, and name
  Future<User?> register(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update the display name in Firebase Auth
      await userCredential.user?.updateDisplayName(name);

      final uid = userCredential.user!.uid;

      // ✅ Save user info to Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("✅ User registered and saved in Firestore.");
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("❌ Registration Error: ${e.message}");
      return null;
    } catch (e) {
      print("❌ Firestore Error: $e");
      return null;
    }
  }


  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
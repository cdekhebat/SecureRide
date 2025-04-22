import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend_model.dart';

class FriendService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<String?> addFriendByEmail(String friendEmail) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) return "Not logged in";

    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return "User not found";

      final friendDoc = query.docs.first;
      final friendUID = friendDoc.id;

      if (friendUID == currentUser.uid) return "Cannot add yourself";

      final friend = Friend.fromMap(friendDoc.data(), friendUID);

      // Save to current user's subcollection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(friendUID)
          .set(friend.toMap());

      return null; // Success
    } catch (e) {
      return "Error: $e";
    }
  }
}

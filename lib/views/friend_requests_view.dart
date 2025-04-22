import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendRequestsView extends StatelessWidget {
  const FriendRequestsView({super.key});

  Future<void> _acceptRequest(String requesterUid, String requesterEmail) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final myUid = currentUser!.uid;
    final myEmail = currentUser.email;

    final firestore = FirebaseFirestore.instance;

    // 1. Add requester to my friends
    await firestore
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(requesterUid)
        .set({
      'email': requesterEmail,
      'addedAt': FieldValue.serverTimestamp(),
    });

    // 2. Add myself to requester's friends
    await firestore
        .collection('users')
        .doc(requesterUid)
        .collection('friends')
        .doc(myUid)
        .set({
      'email': myEmail,
      'addedAt': FieldValue.serverTimestamp(),
    });

    // 3. Remove the incoming request
    await firestore
        .collection('users')
        .doc(myUid)
        .collection('incomingRequests')
        .doc(requesterUid)
        .delete();
  }

  Future<void> _rejectRequest(String requesterUid) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('incomingRequests')
        .doc(requesterUid)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final incomingRef = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('incomingRequests');

    return Scaffold(
      appBar: AppBar(title: const Text("Friend Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: incomingRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("No incoming requests"));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final requesterEmail = doc['email'];
              final requesterUid = doc.id;

              return ListTile(
                title: Text(requesterEmail),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _acceptRequest(requesterUid, requesterEmail),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectRequest(requesterUid),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

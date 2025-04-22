import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddFriendView extends StatelessWidget {
  const AddFriendView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Friend")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Enter your friend's email:"),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: "friend@example.com",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final enteredEmail = emailController.text.trim();
                final currentUser = FirebaseAuth.instance.currentUser;

                if (enteredEmail.isEmpty || currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Email cannot be empty")),
                  );
                  return;
                }

                if (enteredEmail == currentUser.email) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("You cannot add yourself")),
                  );
                  return;
                }

                try {
                  final userQuery = await FirebaseFirestore.instance
                      .collection('users')
                      .where('email', isEqualTo: enteredEmail)
                      .limit(1)
                      .get();

                  if (userQuery.docs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User not found")),
                    );
                    return;
                  }

                  final friendDoc = userQuery.docs.first;
                  final friendUid = friendDoc.id;
                  final senderUid = currentUser.uid;
                  final senderEmail = currentUser.email;

                  final friendSnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(senderUid)
                      .collection('friends')
                      .doc(friendUid)
                      .get();

                  if (friendSnapshot.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("You are already friends")),
                    );
                    return;
                  }

                  final sentSnapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(senderUid)
                      .collection('sentRequests')
                      .doc(friendUid)
                      .get();

                  if (sentSnapshot.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Request already sent")),
                    );
                    return;
                  }

                  // ✅ Send request to friend's incomingRequests
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(friendUid)
                      .collection('incomingRequests') // 👈 Updated
                      .doc(senderUid)
                      .set({
                    'uid': senderUid,
                    'email': senderEmail,
                    'sentAt': FieldValue.serverTimestamp(),
                  });

                  // ✅ Track sent request
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(senderUid)
                      .collection('sentRequests')
                      .doc(friendUid)
                      .set({
                    'uid': friendUid,
                    'email': enteredEmail,
                    'sentAt': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Friend request sent to $enteredEmail")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              },
              child: const Text("Send Friend Request"),
            ),
          ],
        ),
      ),
    );
  }
}

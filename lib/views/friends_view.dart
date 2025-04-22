import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendView extends StatelessWidget {
  const FriendView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Not signed in"));

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    return Scaffold(
      appBar: AppBar(title: const Text("My Friends")),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const Text("Friend Requests", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: userRef.collection('incomingRequests').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final requests = snapshot.data!.docs;

              if (requests.isEmpty) {
                return const Text("No friend requests.");
              }

              return Column(
                children: requests.map((requestDoc) {
                  final senderId = requestDoc.id;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();

                      final sender = snapshot.data!.data() as Map<String, dynamic>;
                      final senderName = sender['name'] ?? 'Unknown';
                      final senderPhoto = sender['photoUrl'];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: senderPhoto != null ? NetworkImage(senderPhoto) : null,
                          child: senderPhoto == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(senderName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.person_add, color: Colors.green),
                              onPressed: () async {
                                final senderDoc = FirebaseFirestore.instance.collection('users').doc(senderId);
                                final senderSnapshot = await senderDoc.get();
                                final senderInfo = senderSnapshot.data() as Map<String, dynamic>?;

                                if (senderInfo != null) {
                                  await userRef.collection('friends').doc(senderId).set({
                                    'name': senderInfo['name'],
                                    'photoUrl': senderInfo['photoUrl'],
                                    'status': 'offline',
                                  });

                                  await senderDoc.collection('friends').doc(currentUser.uid).set({
                                    'name': currentUser.displayName ?? 'Unnamed',
                                    'photoUrl': currentUser.photoURL,
                                    'status': 'offline',
                                  });

                                  await userRef.collection('incomingRequests').doc(senderId).delete();
                                  await senderDoc.collection('sentRequests').doc(currentUser.uid).delete();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Friend added")),
                                    );
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                await userRef.collection('incomingRequests').doc(senderId).delete();
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(senderId)
                                    .collection('sentRequests')
                                    .doc(currentUser.uid)
                                    .delete();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
          const Divider(height: 32),
          const Text("My Friends", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: userRef.collection('friends').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final friends = snapshot.data!.docs;

              if (friends.isEmpty) {
                return const Text("No friends added yet.");
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index].data() as Map<String, dynamic>;
                  final name = friend['name'] ?? 'No name';
                  final status = friend['status'] ?? 'offline';
                  final photoUrl = friend['photoUrl'];
                  final isOnline = status == 'online';
                  final isCrash = status == 'alert';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(name),
                    trailing: Icon(
                      isCrash
                          ? Icons.warning_amber_rounded
                          : isOnline
                          ? Icons.circle
                          : Icons.circle_outlined,
                      color: isCrash
                          ? Colors.red
                          : isOnline
                          ? Colors.green
                          : Colors.grey,
                      size: 16,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

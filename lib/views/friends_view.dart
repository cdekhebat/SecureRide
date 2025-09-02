import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendView extends StatefulWidget {
  const FriendView({super.key});

  @override
  State<FriendView> createState() => _FriendViewState();
}

class _FriendViewState extends State<FriendView> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _busyAccepting = false;
  bool _busyRejecting = false;

  Future<void> _acceptRequest(String senderId) async {
    if (_busyAccepting || currentUser == null) return;
    setState(() => _busyAccepting = true);

    final users = FirebaseFirestore.instance.collection('users');
    final meDoc = users.doc(currentUser!.uid);
    final senderDoc = users.doc(senderId);

    try {
      final meSnap = await meDoc.get();
      final senderSnap = await senderDoc.get();
      final meData = (meSnap.data() as Map<String, dynamic>?) ?? {};
      final senderData = (senderSnap.data() as Map<String, dynamic>?) ?? {};

      final batch = FirebaseFirestore.instance.batch();

      // Add sender to my friends
      batch.set(
        meDoc.collection('friends').doc(senderId),
        {
          'name': senderData['name'] ?? 'Unknown',
          'photoUrl': senderData['photoUrl'] ?? '',
        },
      );

      // Add me to sender's friends
      batch.set(
        senderDoc.collection('friends').doc(currentUser!.uid),
        {
          'name': meData['name'] ?? (currentUser!.displayName ?? 'Unnamed'),
          'photoUrl': meData['photoUrl'] ?? (currentUser!.photoURL ?? ''),
        },
      );

      // Remove requests
      batch.delete(meDoc.collection('incomingRequests').doc(senderId));
      batch.delete(senderDoc.collection('sentRequests').doc(currentUser!.uid));

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Friend request accepted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyAccepting = false);
    }
  }

  Future<void> _rejectRequest(String senderId) async {
    if (_busyRejecting || currentUser == null) return;
    setState(() => _busyRejecting = true);

    final users = FirebaseFirestore.instance.collection('users');
    final meDoc = users.doc(currentUser!.uid);
    final senderDoc = users.doc(senderId);

    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(meDoc.collection('incomingRequests').doc(senderId));
      batch.delete(senderDoc.collection('sentRequests').doc(currentUser!.uid));
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyRejecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Not signed in")),
      );
    }

    final userRef =
    FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);

    return Scaffold(
      appBar: AppBar(title: const Text("My Friends")),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // Friend Requests Section
          const Text("Friend Requests",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: userRef.collection('incomingRequests').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }
              final requests = snapshot.data!.docs;
              if (requests.isEmpty) {
                return const Text("No friend requests.");
              }

              return Column(
                children: requests.map((req) {
                  final senderId = req.id;
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(senderId)
                        .get(),
                    builder: (context, snap) {
                      if (!snap.hasData || !snap.data!.exists) {
                        return const SizedBox.shrink();
                      }
                      final sender =
                          snap.data!.data() as Map<String, dynamic>? ?? {};
                      final senderName = sender['name'] ?? 'Unknown';
                      final senderPhoto = sender['photoUrl'];

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: (senderPhoto is String &&
                                senderPhoto.isNotEmpty)
                                ? NetworkImage(senderPhoto)
                                : null,
                            child: (senderPhoto == null ||
                                (senderPhoto is String &&
                                    senderPhoto.isEmpty))
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(senderName),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Accept',
                                icon: _busyAccepting
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Icon(Icons.person_add,
                                    color: Colors.green),
                                onPressed: _busyAccepting
                                    ? null
                                    : () => _acceptRequest(senderId),
                              ),
                              IconButton(
                                tooltip: 'Reject',
                                icon: _busyRejecting
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Icon(Icons.close,
                                    color: Colors.red),
                                onPressed: _busyRejecting
                                    ? null
                                    : () => _rejectRequest(senderId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),

          const Divider(height: 32),
          const Text("My Friends",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Friends Section
          StreamBuilder<QuerySnapshot>(
            stream: userRef.collection('friends').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LinearProgressIndicator();
              }
              final friends = snapshot.data!.docs;
              if (friends.isEmpty) {
                return const Text("No friends added yet.");
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friendRef = friends[index].reference;

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(friendRef.id)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData || !snap.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      final data = snap.data!.data() as Map<String, dynamic>? ?? {};
                      final name = data['name'] ?? 'No name';
                      final photoUrl = data['photoUrl'];
                      final status = data['status'] ?? 'offline';
                      final crashAt = (data['crashAt'] as Timestamp?)?.toDate();

                      // compute effective status
                      String effectiveStatus = status;
                      if (status == 'alert' && crashAt != null) {
                        final diff = DateTime.now().difference(crashAt);
                        if (diff.inHours >= 2) {
                          effectiveStatus = 'online';

                          // 🔥 update Firestore so all friends see reset
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(friendRef.id)
                              .update({
                            'status': 'online',
                            'crashAt': null,
                          });
                        }
                      }

                      final isOnline = effectiveStatus == 'online';
                      final isCrash = effectiveStatus == 'alert';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                          (photoUrl is String && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                          child: (photoUrl == null || (photoUrl is String && photoUrl.isEmpty))
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(name),
                        trailing: Icon(
                          isCrash
                              ? Icons.warning_amber_rounded
                              : isOnline
                              ? Icons.circle
                              : Icons.circle_outlined,
                          color: isCrash ? Colors.red : isOnline ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                      );
                    },
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

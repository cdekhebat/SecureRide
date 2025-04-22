// profile_view.dart (updated with Post model usage for Firestore storage)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:secureride/views/video_player_screen.dart';
import 'package:secureride/views/video_preview_screen.dart';
import 'package:secureride/models/post.dart'; // ✅ Import Post model

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final user = FirebaseAuth.instance.currentUser;
  String? photoUrl;
  List<Post> videoPosts = []; // ✅ Changed to use Post model

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserVideos();
  }

  Future<void> _loadUserProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    setState(() {
      photoUrl = doc.data()?['photoUrl'];
    });
  }

  Future<void> _loadUserVideos() async {
    final userPostsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('posts')
        .orderBy('timestamp', descending: true);

    final snapshot = await userPostsRef.get();
    setState(() {
      videoPosts = snapshot.docs
          .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('${user!.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}');

    await ref.putFile(File(pickedFile.path));
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'photoUrl': url});
    setState(() => photoUrl = url);
  }

  Future<void> _postVideoFromPreview() async {
    final docDir = await getApplicationDocumentsDirectory();
    final listFile = File(path.join(docDir.path, 'video_list.txt'));
    if (!await listFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No saved dashcam videos available.")),
      );
      return;
    }
    final lines = await listFile.readAsLines();
    final validPaths = lines.where((line) => File(line).existsSync()).toList();
    if (validPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No dashcam videos found.")),
      );
      return;
    }

    String? selectedPath;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Dashcam Video to Upload"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: validPaths.length,
              itemBuilder: (context, index) {
                return FutureBuilder<String?>(
                  future: VideoThumbnail.thumbnailFile(
                    video: validPaths[index],
                    imageFormat: ImageFormat.JPEG,
                    maxWidth: 128,
                    quality: 50,
                  ),
                  builder: (context, snapshot) {
                    return ListTile(
                      leading: snapshot.hasData
                          ? Image.file(File(snapshot.data!), width: 64, height: 64, fit: BoxFit.cover)
                          : const CircularProgressIndicator(),
                      title: Text(path.basename(validPaths[index])),
                      onTap: () => Navigator.pop(context, validPaths[index]),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    ).then((value) => selectedPath = value);

    if (selectedPath == null) return;

    final previewConfirmed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPreviewScreen(videoPath: selectedPath!),
      ),
    );

    if (previewConfirmed != true) return;

    String? caption = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text("Add Caption for Dashcam Video"),
          content: TextField(controller: controller),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Post")),
          ],
        );
      },
    );
    if (caption == null) return;

    final selectedFile = File(selectedPath!);
    final ref = FirebaseStorage.instance
        .ref()
        .child('posts')
        .child('${user!.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(selectedPath!)}');

    await ref.putFile(selectedFile);
    final url = await ref.getDownloadURL();

    final post = Post(
      videoUrl: url,
      caption: caption,
      timestamp: Timestamp.now(),
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('posts')
        .add(post.toMap());

    _loadUserVideos();
  }

  Widget _buildVideoGrid() {
    if (videoPosts.isEmpty) {
      return const Center(child: Text("No videos posted yet."));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: videoPosts.length,
      itemBuilder: (context, index) {
        final post = videoPosts[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(videoPath: post.videoUrl),
            ),
          ),
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
                ),
              ),
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.caption,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '❤️ 0',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null ? const Icon(Icons.person, size: 50) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _uploadProfilePicture,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.add, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _postVideoFromPreview,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Upload Dashcam Video", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("My Dashcam Videos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            _buildVideoGrid(),
          ],
        ),
      ),
    );
  }
}
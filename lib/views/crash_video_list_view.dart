import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../utils/video_player_screen.dart';

class CrashVideoListView extends StatefulWidget {
  const CrashVideoListView({super.key});

  @override
  State<CrashVideoListView> createState() => _CrashVideoListViewState();
}

class _CrashVideoListViewState extends State<CrashVideoListView> {
  List<String> _crashVideos = [];

  @override
  void initState() {
    super.initState();
    _loadCrashVideos();
  }

  Future<void> _loadCrashVideos() async {
    final dir = await getApplicationDocumentsDirectory();
    final crashDir = Directory(p.join(dir.path, 'crash_videos'));

    List<String> crash = [];
    if (await crashDir.exists()) {
      crash = crashDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4'))
          .map((f) => f.path)
          .toList();
    }

    setState(() {
      _crashVideos = crash;
    });
  }

  Future<String?> _generateThumbnail(String videoPath) async {
    return await VideoThumbnail.thumbnailFile(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128,
      quality: 75,
    );
  }

  void _openPlayer(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoPath: path),
      ),
    );
  }

  void _shareVideo(String path) {
    Share.shareXFiles([XFile(path)], text: 'Crash video from SecureRide!');
  }

  Future<void> _deleteVideo(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      _loadCrashVideos();
    }
  }

  Widget _buildVideoGrid(List<String> paths) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: paths.length,
      itemBuilder: (context, index) {
        final path = paths[index];
        return FutureBuilder<String?>(
          future: _generateThumbnail(path),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return GestureDetector(
              onTap: () => _openPlayer(context, path),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(File(snapshot.data!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.basename(path),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'share') _shareVideo(path);
                              if (value == 'delete') _deleteVideo(path);
                            },
                            icon: const Icon(Icons.more_vert, size: 16, color: Colors.white),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'share', child: Text("Share")),
                              const PopupMenuItem(value: 'delete', child: Text("Delete")),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crash Videos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCrashVideos,
          ),
        ],
      ),
      body: _crashVideos.isEmpty
          ? const Center(child: Text("No crash videos available"))
          : _buildVideoGrid(_crashVideos),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'video_player_screen.dart';

class PreviewView extends StatefulWidget {
  const PreviewView({super.key});

  @override
  State<PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<PreviewView> {
  List<String> _videoPaths = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final dir = await getApplicationDocumentsDirectory();
    final listFile = File(p.join(dir.path, 'video_list.txt'));

    List<String> validPaths = [];

    if (await listFile.exists()) {
      final lines = await listFile.readAsLines();
      for (String path in lines) {
        if (await File(path).exists()) {
          validPaths.add(path);
        }
      }

      // Update list file with only valid paths
      await listFile.writeAsString(validPaths.join('\n'));
    }

    setState(() {
      _videoPaths = validPaths;
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

  void _shareVideo(String path) {
    Share.shareXFiles([XFile(path)], text: 'Check out this video from SecureRide!');
  }

  Future<void> _deleteVideo(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();

      final dir = await getApplicationDocumentsDirectory();
      final listFile = File(p.join(dir.path, 'video_list.txt'));

      if (await listFile.exists()) {
        final lines = await listFile.readAsLines();
        final updatedLines = lines.where((line) => line.trim() != path.trim()).toList();
        await listFile.writeAsString(updatedLines.join('\n'));
      }

      _loadVideos();
    }
  }

  void _openPlayer(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoPath: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preview Videos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
          ),
        ],
      ),
      body: _videoPaths.isEmpty
          ? const Center(child: Text("No preview videos available"))
          : GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: _videoPaths.length,
        itemBuilder: (context, index) {
          final path = _videoPaths[index];

          return FutureBuilder<String?>(
            future: _generateThumbnail(path),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                p.basename(path),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'share') {
                                  _shareVideo(path);
                                } else if (value == 'delete') {
                                  _deleteVideo(path);
                                }
                              },
                              icon: const Icon(
                                Icons.more_vert,
                                size: 16,
                                color: Colors.white,
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Text("Share"),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text("Delete"),
                                ),
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
      ),
    );
  }
}
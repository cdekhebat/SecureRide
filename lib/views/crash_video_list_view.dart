import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as p;
import 'video_player_screen.dart'; // ✅ import here

class CrashVideoListView extends StatelessWidget {
  final List<String> videos;

  const CrashVideoListView({super.key, required this.videos});

  Future<String?> _generateThumbnail(String videoPath) async {
    return await VideoThumbnail.thumbnailFile(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 128,
      quality: 75,
    );
  }

  void _openVideo(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoPath: path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validVideos = videos.where((v) => File(v).existsSync()).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Crash Videos')),
      body: validVideos.isEmpty
          ? const Center(child: Text('No crash videos recorded'))
          : ListView.builder(
        itemCount: validVideos.length,
        itemBuilder: (context, index) {
          final video = validVideos[index];
          return FutureBuilder<String?>(
            future: _generateThumbnail(video),
            builder: (context, snapshot) {
              return ListTile(
                leading: snapshot.hasData && File(snapshot.data!).existsSync()
                    ? Image.file(File(snapshot.data!), width: 64, height: 64, fit: BoxFit.cover)
                    : const SizedBox(width: 64, height: 64, child: Center(child: CircularProgressIndicator())),
                title: Text(p.basename(video)),
                onTap: () => _openVideo(context, video),
              );
            },
          );
        },
      ),
    );
  }
}

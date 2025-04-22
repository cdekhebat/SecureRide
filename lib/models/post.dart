import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String videoUrl;
  final String caption;
  final Timestamp timestamp;

  Post({
    required this.videoUrl,
    required this.caption,
    required this.timestamp,
  });

  // Convert Dart class to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'videoUrl': videoUrl,
      'caption': caption,
      'timestamp': timestamp,
    };
  }

  // Convert Firestore document to Dart class
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      videoUrl: map['videoUrl'] ?? '',
      caption: map['caption'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}

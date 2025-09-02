// 1. First, update camera_service.dart to handle both manual and crash recordings
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  Timer? _loopTimer;
  bool isRecording = false;
  String? _lastLoopPath;

  CameraController? get controller => _controller;
  String? getLoopVideoPath() => _lastLoopPath;

  Future<void> initializeCamera() async {
    if (_controller != null && _controller!.value.isInitialized) return;

    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final firstCamera = cameras.first;
    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: true,
    );
    await _controller!.initialize();
  }

  Future<void> startLoopRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (isRecording) return;

    isRecording = true;
    await _recordNewLoop();
    _loopTimer = Timer.periodic(const Duration(minutes: 5), (_) => _recordNewLoop());
  }

  Future<void> _recordNewLoop() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_controller!.value.isRecordingVideo) {
      final file = await _controller!.stopVideoRecording();
      _lastLoopPath = file.path;
    }

    await _controller!.startVideoRecording();
  }

  Future<String?> stopLoopRecording() async {
    isRecording = false;
    _loopTimer?.cancel();

    if (_controller != null && _controller!.value.isRecordingVideo) {
      final file = await _controller!.stopVideoRecording();
      _lastLoopPath = file.path;
      return file.path;
    }
    return _lastLoopPath;
  }

  // Existing manual save function (unchanged)
  Future<String?> saveManualRecording() async {
    debugPrint("🟡 Attempting to save manual recording");
    if (!isRecording) {
      debugPrint("🔴 Not recording");
      return null;
    }

    if (_lastLoopPath == null || !File(_lastLoopPath!).existsSync()) {
      debugPrint("🔴 No valid _lastLoopPath or file does not exist: $_lastLoopPath");
      return null;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final previewDir = Directory(path.join(dir.path, 'preview_videos'));
      if (!await previewDir.exists()) await previewDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final previewPath = path.join(previewDir.path, 'manual_$timestamp.mp4');
      final copied = await File(_lastLoopPath!).copy(previewPath);

      debugPrint("✅ Copied video to: $previewPath");
      return copied.path;
    } catch (e) {
      debugPrint("❌ Exception while saving manual recording: $e");
      return null;
    }
  }

  // NEW: Function to save crash videos
  Future<String?> saveCrashRecording() async {
    debugPrint("🟡 Attempting to save crash recording");
    if (!isRecording) {
      debugPrint("🔴 Not recording");
      return null;
    }

    if (_lastLoopPath == null || !File(_lastLoopPath!).existsSync()) {
      debugPrint("🔴 No valid _lastLoopPath or file does not exist: $_lastLoopPath");
      return null;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final crashDir = Directory(path.join(dir.path, 'crash_videos'));
      if (!await crashDir.exists()) await crashDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final crashPath = path.join(crashDir.path, 'crash_$timestamp.mp4');
      final copied = await File(_lastLoopPath!).copy(crashPath);

      debugPrint("✅ Saved crash video to: $crashPath");
      return copied.path;
    } catch (e) {
      debugPrint("❌ Exception while saving crash recording: $e");
      return null;
    }
  }
}
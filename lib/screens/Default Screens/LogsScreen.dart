import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isStreaming = false;
  Timer? _captureTimer;
  int _frameCount = 0;
  String _uploadStatus = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameraPermission = await Permission.camera.request();
    if (cameraPermission != PermissionStatus.granted) {
      setState(() {
        _uploadStatus = 'Camera permission denied';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() {
          _uploadStatus = 'No cameras available';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() {
        _isInitialized = true;
        _uploadStatus = 'Camera initialized';
      });

      // Auto start streaming when camera is ready
      _startStreaming();
    } catch (e) {
      setState(() {
        _uploadStatus = 'Error initializing camera: $e';
      });
    }
  }

  Future<void> _startStreaming() async {
    if (!_isInitialized || _cameraController == null) return;

    setState(() {
      _isStreaming = true;
      _frameCount = 0;
      _uploadStatus = 'Starting stream...';
    });

    // Capture frames every 2 seconds (adjust as needed)
    _captureTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _captureAndUploadFrame();
    });
  }

  Future<void> _stopStreaming() async {
    _captureTimer?.cancel();
    setState(() {
      _isStreaming = false;
      _uploadStatus = 'Stream stopped';
    });
  }

  Future<void> _captureAndUploadFrame() async {
    if (!_isInitialized || _cameraController == null) return;

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      // Generate unique filename
      final String fileName =
          'frames/frame_${DateTime.now().millisecondsSinceEpoch}_$_frameCount.jpg';

      // Upload to Firebase Storage
      await _uploadToFirebase(imageBytes, fileName);

      setState(() {
        _frameCount++;
        _uploadStatus = 'Uploaded frame $_frameCount';
      });
    } catch (e) {
      setState(() {
        _uploadStatus = '';
      });
    }
  }

  Future<void> _uploadToFirebase(Uint8List imageBytes, String fileName) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final Reference ref = storage.ref().child(fileName);

      // Upload the file
      final UploadTask uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'timestamp': DateTime.now().toIso8601String(),
            'frame_number': _frameCount.toString(),
          },
        ),
      );

      // Wait for upload to complete
      await uploadTask;

      // Get download URL (optional)
      final String downloadURL = await ref.getDownloadURL();
      print('Frame uploaded: $downloadURL');
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentCameraIndex =
        _cameras!.indexOf(_cameraController!.description);
    final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

    await _cameraController?.dispose();

    _cameraController = CameraController(
      _cameras![newCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Stream'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: _isInitialized && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          ),

          // Status and Controls
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Status Text
                    Text(
                      _uploadStatus,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Frame Count
                    Text(
                      'Frames captured: $_frameCount',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Show "Stop Stream" only if streaming
                        _isStreaming
                            ? ElevatedButton(
                                onPressed: _stopStreaming,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Stop Stream'),
                              )
                            : const Text(
                                'Streaming stopped',
                                style: TextStyle(color: Colors.grey),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

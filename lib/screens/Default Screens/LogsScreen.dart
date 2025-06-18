import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';

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
  Timer? _warningTimer;
  String _lastGazeDirection = 'center'; // Default safe state
  String _gazeStatus = 'Waiting for gaze direction...'; // NEW VARIABLE for UI

  late final AudioPlayer _audioPlayer;
  DatabaseReference? _gazeRef;
  StreamSubscription<DatabaseEvent>? _dbSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeCamera();
    _listenToGazeDirection(); // Listen to Realtime Database
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

      // Find the front camera first, fallback to first available camera
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera, // Use front camera instead of _cameras!.first
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() {
        _isInitialized = true;
        _uploadStatus = 'Camera initialized (Front Camera)';
      });

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
      final XFile image = await _cameraController!.takePicture();
      final Uint8List imageBytes = await image.readAsBytes();

      final String fileName =
          'frames/frame_${DateTime.now().millisecondsSinceEpoch}_$_frameCount.jpg';

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

      await uploadTask;
      final String downloadURL = await ref.getDownloadURL();
      print('Frame uploaded: $downloadURL');
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  void _switchToFrontCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    // Find the front camera
    final frontCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    await _cameraController?.dispose();

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    setState(() {});
  }

  void _listenToGazeDirection() {
    _gazeRef = FirebaseDatabase.instance.ref('driver_status/gaze_direction');

    _dbSubscription = _gazeRef!.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      print('Gaze Direction: $data');
      if (data != null) {
        final gazeDirection = data.toString();

        // Update the status text for the UI
        setState(() {
          if (gazeDirection == 'left') {
            _gazeStatus = 'Looking Left';
          } else if (gazeDirection == 'right') {
            _gazeStatus = 'Looking Right';
          } else {
            _gazeStatus = 'Looking Ahead';
          }
        });

        // Only act if gazeDirection changes
        if (gazeDirection != _lastGazeDirection) {
          _lastGazeDirection = gazeDirection;

          if (gazeDirection == 'left' || gazeDirection == 'right') {
            _startWarningTimer();
          } else {
            _stopWarningTimer();
          }
        }
      }
    });
  }

  void _startWarningTimer() {
    _warningTimer?.cancel(); // cancel any existing timer
    _warningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _playWarningSound();
    });
  }

  void _stopWarningTimer() {
    _warningTimer?.cancel();
    _warningTimer = null;
  }

  Future<void> _playWarningSound() async {
    await _audioPlayer.play(AssetSource('sounds/warning_sound.mp3'));
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    _dbSubscription?.cancel();
    _warningTimer?.cancel(); // Clean up
    _audioPlayer.dispose();
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
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      _uploadStatus,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Frames captured: $_frameCount',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gaze Direction: $_gazeStatus', // Display Gaze Status here
                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
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

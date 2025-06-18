import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class EmergencyService {
  // Singleton instance
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  // Firebase
  final databaseRef = FirebaseDatabase.instance.ref();
  final firestore = FirebaseFirestore.instance;
  final player = AudioPlayer();

  // State
  bool warningPlaying = false;
  BuildContext? appContext;

  // Data
  String latestStatus = '';
  int latestHeartRate = 999; // Initialize with impossible HR value

  void setContext(BuildContext context) {
    appContext = context;
  }

  void startMonitoring() {
    // Listen to Heart Rate
    databaseRef.child('heart_rate/raw').onValue.listen((event) {
      final hrValue = event.snapshot.value;
      if (hrValue != null) {
        latestHeartRate = int.tryParse(hrValue.toString()) ?? 999;
        print('Heart Rate: $latestHeartRate');
        _checkEmergencyCondition();
      }
    });

    // Listen to Latest Image Status (Get only the latest)
    databaseRef
        .child('images')
        .orderByKey()
        .limitToLast(1)
        .onChildAdded
        .listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      latestStatus = data['status'] ?? '';
      final accuracy = data['accuracy'];
      print('Latest Image Status: $latestStatus, Accuracy: $accuracy');
      _checkEmergencyCondition();
    });

    // Optionally: Listen to 'status' node directly (legacy)
    // databaseRef.child('status').onValue.listen((statusEvent) async {
    //   final statusValue = statusEvent.snapshot.value;
    //   if (statusValue != null) {
    //     latestStatus = statusValue.toString();
    //     print("Status Node Value: $latestStatus");
    //     _checkEmergencyCondition();
    //   }
    // });
  }

  // Emergency condition checking logic
  Future<void> _checkEmergencyCondition() async {
    // Fetch latest image status
    final imagesSnap =
        await databaseRef.child('images').orderByKey().limitToLast(1).get();
    if (imagesSnap.children.isNotEmpty) {
      final child = imagesSnap.children.first;
      final data = Map<String, dynamic>.from(child.value as Map);
      latestStatus = data['status'] ?? '';
      print('Fetched Latest Image Status (in HR Check): $latestStatus');
    }

    print('Checking Emergency: status=$latestStatus, heart=$latestHeartRate');

    if (latestStatus == 'c11') {
      if (!warningPlaying) {
        warningPlaying = true;

        await player.play(AssetSource('sounds/warning_sound.mp3'));
        await Future.delayed(Duration(seconds: 5));

        // Re-fetch latest after delay:
        final imagesSnapAfterDelay =
            await databaseRef.child('images').orderByKey().limitToLast(1).get();
        String latestStatusAfterDelay = "";
        if (imagesSnapAfterDelay.children.isNotEmpty) {
          final child = imagesSnapAfterDelay.children.first;
          final data = Map<String, dynamic>.from(child.value as Map);
          latestStatusAfterDelay = data['status'] ?? '';
        }

        final heartSnap = await databaseRef.child('heart_rate/raw').get();
        final latestHeartRateAfterDelay =
            int.tryParse(heartSnap.value.toString()) ?? 999;

        print(
            "Recheck After Delay: status=$latestStatusAfterDelay, heart=$latestHeartRateAfterDelay");

        if (latestStatusAfterDelay == 'c11' && latestHeartRateAfterDelay < 60) {
          await handleEmergency();
        }

        warningPlaying = false;
      }
    }
  }

  // Handle Emergency: Send Email + Make Call
  Future<void> handleEmergency() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await firestore.collection('users').doc(user.uid).get();
        final data = doc.data();
        if (data != null && data['emergencyContact'] != null) {
          final emergencyContact = data['emergencyContact'];
          final email = emergencyContact['email'];
          final phone = emergencyContact['phone'];

          // Show dialog
          if (appContext != null) {
            showDialog(
              context: appContext!,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text("Emergency Detected!"),
                content: const Text("Emergency actions are being taken."),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK")),
                ],
              ),
            );
          }

          // Send Email
          final emailUri = Uri(
            scheme: 'mailto',
            path: email,
            query: 'subject=Emergency Alert&body=Driver in danger!',
          );
          if (await canLaunchUrl(emailUri)) await launchUrl(emailUri);

          // Make Phone Call
          final telUri = Uri(scheme: 'tel', path: phone);
          if (await canLaunchUrl(telUri)) await launchUrl(telUri);

          print("Emergency triggered: $email, $phone");
        }
      }
    } catch (e) {
      print("Error during emergency handling: $e");
    }
  }
}

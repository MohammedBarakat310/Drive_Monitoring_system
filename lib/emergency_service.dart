import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmergencyServiceManager {
  EmergencyServiceManager._();

  static const double _sleepHeartRateThreshold = 60; // bpm
  static const double _faintHeartRateThreshold = 40; // bpm

  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final AudioPlayer _player = AudioPlayer();

  static StreamSubscription<DatabaseEvent>? _statusSub;
  static StreamSubscription<DatabaseEvent>? _heartrateSub;

  static String _status = '';
  static double _heartrate = 0;

  static Future<void> initialize() async {
    _listenStatus();
    _listenHeartRate();
  }

  static void dispose() {
    _statusSub?.cancel();
    _heartrateSub?.cancel();
    _player.dispose();
  }

  static void _listenStatus() {
    _statusSub = _database.ref('driver_status/status').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        _status = data.toString();
        _checkEmergency();
      }
    });
  }

  static void _listenHeartRate() {
    _heartrateSub =
        _database.ref('driver_status/heart_rate').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        _heartrate = double.tryParse(data.toString()) ?? 0;
        _checkEmergency();
      }
    });
  }

  static Future<void> _checkEmergency() async {
    if (_status == 'c10' && _heartrate <= _sleepHeartRateThreshold) {
      await _player.play(AssetSource('sounds/warning_sound.mp3'));
    } else if (_status == 'c11' && _heartrate <= _faintHeartRateThreshold) {
      await _triggerEmergencyActions();
    }
  }

  static Future<void> _triggerEmergencyActions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data == null) return;
    final contact = data['emergencyContact'];
    if (contact == null) return;

    final phone = contact['phone'] as String?;
    final email = contact['email'] as String?;
    print(email);
    final firstname = contact['firstname'] ?? '';
    final lastname = contact['lastname'] ?? '';

    final locSnapshot = await _database.ref('driver_status/location').get();
    final lat = locSnapshot.child('latitude').value;
    final lng = locSnapshot.child('longitude').value;
    final location = '$lat,$lng';

    if (email != null) {
      await _sendEmail(email, '$firstname $lastname', location);
    }

    if (phone != null) {
      FlutterPhoneDirectCaller.callNumber("$phone");
    }
  }

  static Future<void> _sendEmail(
      String toEmail, String name, String location) async {
    const String username = 'm35130496@gmail.com';
    const String password = 'gewqvomppxsqhsoq';

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Driver Monitoring')
      ..recipients.add(toEmail)
      ..subject = 'EMERGENCY ALERT - Immediate Attention Required'
      ..text =
          'The driver may have fainted.\nContact name: $name\nLocation: $location';

    try {
      await send(message, smtpServer);
    } catch (e) {
      print(e.toString());
    }
  }
}

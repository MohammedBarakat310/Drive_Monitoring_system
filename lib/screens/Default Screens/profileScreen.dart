import 'dart:io';
import 'package:flutter/material.dart';
import 'package:grad_project/screens/Login%20and%20Registraion/SignInScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  File? selectedImage;
  String? userId;
  String? username;
  String? email;
  String? CarNumber;
  bool isLoading = false;

  @override
  bool get wantKeepAlive => true; // Keep screen state even after navigation

  @override
  void initState() {
    super.initState();
    userId =
        FirebaseAuth.instance.currentUser?.uid; // Get the current user's UID
    if (userId != null) {
      loadImage(); // Load image from Firestore when the screen is initialized
      loadProfileData();
    }
  }

  Future<void> loadProfileData() async {
    setState(() {
      isLoading = true;
    });

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        username = userDoc['username'];
        email = userDoc['email'];
        CarNumber = userDoc['carNumber'];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  // Load the image from Firestore when the app is restarted
  Future<void> loadImage() async {
    if (userId == null) return; // Ensure user is logged in

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      String? savedPath =
          userDoc['profilePicture']; // Get the stored image path
      if (savedPath != null && File(savedPath).existsSync()) {
        setState(() {
          selectedImage = File(savedPath); // Load the image from Firestore path
        });
      }
    }
  }

  // Pick an image from the gallery and save it in Firestore
  Future<void> pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;

    setState(() {
      selectedImage = File(returnedImage.path); // Set selected image
    });

    // Save the image path to Firestore under the current user's document
    if (userId != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profilePicture': returnedImage.path, // Save the image file path
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(
        context); // Call super.build when using AutomaticKeepAliveClientMixin

    return Scaffold(
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  GestureDetector(
                    onTap: pickImageFromGallery,
                    child: selectedImage != null
                        ? CircleAvatar(
                            backgroundImage: FileImage(selectedImage!),
                            radius: 70,
                          )
                        : const CircleAvatar(
                            radius: 70,
                            child: Text('Tap to select image'),
                          ),
                  ),
                  SizedBox(
                    height: 60,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 310),
                    child: Text(
                      'Info',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (username != null)
                    buildInfoTile(
                      icon: Icons.person,
                      title: "Name",
                      value: username!,
                    ),
                  if (CarNumber != null)
                    buildInfoTile(
                      icon: Icons.directions_car,
                      title: "Car Number",
                      value: CarNumber!,
                    ),
                  if (email != null)
                    buildInfoTile(
                      icon: Icons.email,
                      title: "Email",
                      value: email!,
                    ),
                  const SizedBox(height: 70),
                  SizedBox(
                    width: 300,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignIn_Screen(),
                          ),
                        );
                      },
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

Widget buildInfoTile(
    {required IconData icon, required String title, required String value}) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    ),
  );
}

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true; //disable back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home Screen'),
          automaticallyImplyLeading: false, // Remove back button
        ),
        body: Center(
          child: Text("Welcome to Home Screen!"),
        ),
      ),
    );
  }
}

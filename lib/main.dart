import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:grad_project/screens/onBoarding.dart';
import 'package:grad_project/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      routes: {
        Splash_Screen.id: (context) => Splash_Screen(),
        onboardingScreen.id: (context) => onboardingScreen()
      },
      initialRoute: Splash_Screen.id,
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:grad_project/screens/AddProfileScreen.dart';
import 'package:grad_project/screens/SignInScreen.dart';
import 'package:grad_project/screens/SignUpScreen.dart';
import 'package:grad_project/screens/onBoarding.dart';
import 'package:grad_project/screens/splash_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
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
        Splash_Screen.id: (context) => const Splash_Screen(),
        onboardingScreen.id: (context) => const onboardingScreen(),
        SignIn_Screen.id: (context) => const SignIn_Screen(),
        SignUpScreen.id: (context) => const SignUpScreen(),
      },
      initialRoute: Splash_Screen.id,
    );
  }
}

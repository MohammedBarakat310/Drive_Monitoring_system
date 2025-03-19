import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:grad_project/screens/Splash%20and%20OnBoarding/onBoarding.dart';
import 'package:lottie/lottie.dart';

class Splash_Screen extends StatelessWidget {
  const Splash_Screen({super.key});

  static String id = 'Splash_Screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedSplashScreen(
          splash: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animation/Animation - 1738951429345.json',
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.5,
                fit: BoxFit.contain,
              ),
            ],
          ),
          nextScreen: const onboardingScreen(),
          duration: 2000,
          backgroundColor: Colors.white,
          splashIconSize: MediaQuery.of(context).size.height * 0.6,
        ),
      ),
    );
  }
}

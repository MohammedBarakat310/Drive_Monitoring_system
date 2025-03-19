import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grad_project/controllers/onBoardingCont.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class onboardingScreen extends StatelessWidget {
  const onboardingScreen({super.key});
  static String id = 'onboarding';

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(onboardingController());
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller.pagecontroller,
            onPageChanged: controller.updatePageIndicator,
            children: [
              OnboardingPage(
                image: 'assets/gifs/1.json',
                title: 'Welcome to Your Driver Monitoring System',
                subtitlel:
                    'Stay safe on the road with real-time alerts and insights about your driving behavior and focus.',
              ),
              OnboardingPage(
                image: 'assets/gifs/Animation - 1741201080923.json',
                title: 'Your Safety Companion',
                subtitlel:
                    'Monitors driver fatigue and distraction\n\nAlerts you in real-time to stay focused\n\nTracks driving patterns for better habits.',
              ),
              OnboardingPage(
                image: 'assets/gifs/3.json',
                title: 'How It Works',
                subtitlel:
                    'The system uses advanced sensors and AI to monitor your face and eyes\n\nIt alerts you if you’re drowsy, distracted, or not looking at the road\n\nStay informed with regular driving reports.',
              ),
              OnboardingPage(
                image: 'assets/gifs/4.json',
                title: 'Lets Get Started',
                subtitlel:
                    'Allow camera access for driver monitoring\n\nEnable notifications for real-time alerts\n\n',
              ),
            ],
          ),

          //the code below for skip button
          skipButton(),

          //the code below for the indicator
          dotNavigation(),

          //the code below for circular button to navigate

          nextButton()
        ],
      ),
    );
  }
}

class nextButton extends StatelessWidget {
  const nextButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: kToolbarHeight,
      right: 20,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          backgroundColor: Colors.black,
        ),
        onPressed: () => onboardingController.instance.nextPage(),
        child: Icon(Iconsax.arrow_right_3),
      ),
    );
  }
}

class skipButton extends StatelessWidget {
  const skipButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: kToolbarHeight,
      right: 10,
      child: TextButton(
        onPressed: () => onboardingController.instance.skipPage(),
        child: const Text(
          'Skip',
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}

class dotNavigation extends StatelessWidget {
  const dotNavigation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = onboardingController.instance;
    return Positioned(
      bottom: kToolbarHeight,
      left: 20,
      child: SmoothPageIndicator(
        controller: controller.pagecontroller,
        onDotClicked: controller.dotNavigationClick,
        count: 4,
        effect: ExpandingDotsEffect(
            activeDotColor: Colors.black, dotWidth: 10, dotHeight: 6),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage(
      {super.key,
      required this.image,
      required this.title,
      required this.subtitlel});

  final String image, title, subtitlel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(9),
      child: Column(
        children: [
          Lottie.asset(
            image,
            width: (MediaQuery.of(Get.context!).size.width) * .93,
            height: (MediaQuery.of(Get.context!).size.height) * 0.6,
            fit: BoxFit.contain,
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 30,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 30,
          ),
          Text(
            subtitlel,
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
            ),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}

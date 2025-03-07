import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grad_project/screens/SignInScreen.dart';

class onboardingController extends GetxController {
  static onboardingController get instance => Get.find();

  final pagecontroller = PageController();

  Rx<int> currentindex = 0.obs;

  void updatePageIndicator(index) => currentindex.value = index;

  void dotNavigationClick(index) {
    currentindex.value = index;
    pagecontroller.jumpToPage(index);
  }

  void nextPage() {
    if (currentindex.value == 3) {
      Get.offAll(() => SignIn_Screen());
    } else {
      int page = currentindex.value + 1;
      pagecontroller.jumpToPage(page);
    }
  }

  void skipPage() {
    Get.offAll(() => SignIn_Screen());
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grad_project/authWrapper.dart';
import 'package:grad_project/screens/Login%20and%20Registraion/SignInScreen.dart';

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
      Get.offAll(() => AuthWrapper());
    } else {
      int page = currentindex.value + 1;
      pagecontroller.jumpToPage(page);
    }
  }

  void skipPage() {
    Get.offAll(() => AuthWrapper());
  }
}

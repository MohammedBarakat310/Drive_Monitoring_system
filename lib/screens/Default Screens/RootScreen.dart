import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:grad_project/screens/Default%20Screens/EmergencyScreen.dart';
import 'package:grad_project/screens/Default%20Screens/HomeScreen.dart';
import 'package:grad_project/screens/Default%20Screens/LogsScreen.dart';
import 'package:grad_project/screens/Default%20Screens/profileScreen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int Selectedindex = 0;

  final PageController pageController = PageController();

  final List<Widget> screens = [
    const HomeScreen(),
    const LogsScreen(),
    const EmergencyScreen(),
    const ProfileScreen()
  ];
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; //disable back navigation
      },
      child: Scaffold(
        body: PageView(
          controller: pageController,
          children: screens,
          onPageChanged: (value) {
            setState(() {
              Selectedindex = value;
            });
          },
        ),
        bottomNavigationBar: GNav(
          activeColor: Colors.blue,
          curve: Curves.easeInCirc,
          backgroundColor: Colors.grey.shade500,
          color: Colors.white,
          selectedIndex: Selectedindex,
          onTabChange: (value) {
            setState(() {
              Selectedindex = value;
              pageController.jumpToPage(value);
            });
          },
          textStyle: TextStyle(
            color: Colors.white,
          ),
          tabBackgroundColor: Colors.grey.shade400,
          gap: 8,
          tabs: [
            GButton(
              icon: Icons.home,
              text: 'Home',
            ),
            GButton(
              icon: Icons.trip_origin_sharp,
              text: 'Logs',
            ),
            GButton(
              icon: Icons.emergency,
              text: 'Emergency',
            ),
            GButton(
              icon: Icons.settings,
              text: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

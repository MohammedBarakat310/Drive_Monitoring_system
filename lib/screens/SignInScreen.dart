import 'package:flutter/material.dart';
import 'package:grad_project/components/TextFormField.dart';
import 'package:grad_project/screens/SignUpScreen.dart';
import 'package:iconsax/iconsax.dart';

// ignore: camel_case_types
class SignIn_Screen extends StatelessWidget {
  const SignIn_Screen({super.key});
  static String id = 'signIn';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFFFFF),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 56,
            bottom: 24,
            right: 24,
            left: 24,
          ),
          child: Column(
            children: [
              //first section
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Image(
                      image: AssetImage(
                          'assets/animation/istockphoto-2164339311-612x612.png'),
                      height: 150,
                    ),
                    Text(
                      'Drive Smart, Stay Safe',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.black),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      'Sign in to start monitoring your journey.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.black, fontSize: 17),
                    ),
                  ],
                ),
              ),
              //second section

              Form(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const specialTextField(
                        label: 'E-Mail',
                        mainIcon: Iconsax.direct_right,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const specialTextField(
                        label: 'Password',
                        mainIcon: Iconsax.password_check,
                        secondIcon: Iconsax.eye_slash,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: false,
                                onChanged: (value) {},
                              ),
                              const Text('Remeber me'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.black.withOpacity(.8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, SignUpScreen.id);
                          },
                          child: Text(
                            'Create account',
                            style: TextStyle(
                              color: Colors.black.withOpacity(.8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 32,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

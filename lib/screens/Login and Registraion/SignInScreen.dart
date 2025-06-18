import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grad_project/components/TextFormField.dart';
import 'package:grad_project/screens/Default%20Screens/RootScreen.dart';
import 'package:grad_project/screens/Login%20and%20Registraion/SignUpScreen.dart';
import 'package:iconsax/iconsax.dart';

// ignore: camel_case_types
class SignIn_Screen extends StatefulWidget {
  const SignIn_Screen({super.key});
  static String id = 'signIn';

  @override
  State<SignIn_Screen> createState() => _SignIn_ScreenState();
}

class _SignIn_ScreenState extends State<SignIn_Screen> {
  final form = GlobalKey<FormState>();
  FirebaseAuth auth = FirebaseAuth.instance;
  bool isloading = false;

  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();

  Future<void> signIn() async {
    setState(() {
      isloading = true;
    });

    try {
      UserCredential user = await auth.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RootScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = '';

      // Handle specific error codes
      if (e.code == 'user-not-found') {
        errorMessage = 'The user is not found';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password. Please try again';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid';
      } else {
        errorMessage = '${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Handle general errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isloading = false;
      });
    }
  }

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
                key: form,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      specialTextField(
                        label: 'E-Mail',
                        mainIcon: Iconsax.direct_right,
                        controller: email,
                        validator: (p0) {
                          if (p0 == null || p0.isEmpty) {
                            return 'please enter the E-Mail';
                          }
                        },
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      specialTextField(
                        label: 'Password',
                        mainIcon: Iconsax.password_check,
                        secondIcon: Iconsax.eye_slash,
                        controller: pass,
                        obscure: true,
                        validator: (p0) {
                          if (p0 == null || p0.isEmpty) {
                            return 'Please enter the password';
                          }
                        },
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
                                onChanged: (value) {
                                  setState(() {
                                    value != value;
                                  });
                                },
                              ),
                              const Text('Remeber me'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (form.currentState!.validate()) {
                      signIn();
                    }
                  },
                  child: Text(
                    isloading ? 'Signing...' : 'Sign In',
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
    );
  }
}

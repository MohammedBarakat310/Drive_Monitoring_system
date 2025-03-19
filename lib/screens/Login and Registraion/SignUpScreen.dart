import 'package:flutter/material.dart';
import 'package:grad_project/components/SpecialButton.dart';
import 'package:grad_project/components/TextFormField.dart';
import 'package:grad_project/screens/Login%20and%20Registraion/AddProfileScreen.dart';
import 'package:iconsax/iconsax.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  static String id = 'signUp';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController Fname = TextEditingController();
  final TextEditingController Lname = TextEditingController();
  final TextEditingController Uname = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController Cnumber = TextEditingController();
  final TextEditingController pass = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Let\'s Create Your Account',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: specialTextField(
                            label: 'First Name',
                            mainIcon: Iconsax.user,
                            controller: Fname,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your first name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: specialTextField(
                            label: 'Last Name',
                            mainIcon: Iconsax.user,
                            controller: Lname,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your last name';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    specialTextField(
                      label: 'User Name',
                      mainIcon: Iconsax.user_edit,
                      controller: Uname,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    specialTextField(
                      label: 'E-Mail',
                      mainIcon: Iconsax.direct,
                      controller: email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    specialTextField(
                      label: 'Car Number',
                      mainIcon: Iconsax.car,
                      controller: Cnumber,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your car number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    specialTextField(
                      label: 'Password',
                      obscure: true,
                      mainIcon: Iconsax.password_check,
                      secondIcon: Iconsax.eye_slash,
                      controller: pass,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    specialButton(
                      function: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddProfile(
                                firstName: Fname.text.trim(),
                                lastName: Lname.text.trim(),
                                username: Uname.text.trim(),
                                email: email.text.trim(),
                                carNumber: Cnumber.text.trim(),
                                pass: pass.text.trim(),
                              ),
                            ),
                          );
                        }
                      },
                      text: 'Continue',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

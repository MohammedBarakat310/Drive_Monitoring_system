import 'package:flutter/material.dart';
import 'package:grad_project/components/SpecialButton.dart';
import 'package:grad_project/components/TextFormField.dart';
import 'package:grad_project/screens/AddProfileScreen.dart';
import 'package:iconsax/iconsax.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});
  static String id = 'signUp';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Let\'s Create Your Account',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(
                height: 32,
              ),

              //form
              Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        //first name
                        Expanded(
                          child: specialTextField(
                            label: 'First Name',
                            mainIcon: Iconsax.user,
                          ),
                        ),

                        SizedBox(
                          width: 16,
                        ),

                        //last name
                        Expanded(
                          child: specialTextField(
                            label: 'Last Name',
                            mainIcon: Iconsax.user,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    //username

                    const specialTextField(
                      label: 'User Name',
                      mainIcon: Iconsax.user_edit,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    //E-mail

                    const specialTextField(
                      label: 'E-Mail',
                      mainIcon: Iconsax.direct,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    //car number
                    const specialTextField(
                      label: 'Car Number',
                      mainIcon: Iconsax.car,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    //password

                    const specialTextField(
                      label: 'Password',
                      mainIcon: Iconsax.password_check,
                      secondIcon: Iconsax.eye_slash,
                    ),
                    const SizedBox(
                      height: 30,
                    ),

                    //terms and conditions

                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: true,
                            onChanged: (value) {},
                          ),
                        ),
                        SizedBox(
                          width: 16,
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'I agree to ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .apply(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline),
                              ),
                              TextSpan(
                                text: ' and ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              TextSpan(
                                text: 'Terms of use',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .apply(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    //sign up button

                    specialButton(
                      function: () =>
                          Navigator.pushNamed(context, AddProfile.id),
                      text: 'Continue',
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

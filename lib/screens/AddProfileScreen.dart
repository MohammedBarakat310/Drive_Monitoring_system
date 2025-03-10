import 'package:flutter/material.dart';
import 'package:grad_project/components/SpecialButton.dart';
import 'package:grad_project/components/TextFormField.dart';
import 'package:iconsax/iconsax.dart';

class AddProfile extends StatelessWidget {
  const AddProfile({super.key});
  static String id = 'addprofile';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For your safety we want you to put some information about who we can call at emergency situation',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .apply(color: Colors.black),
              ),
              const SizedBox(
                height: 32,
              ),
              const Form(
                child: Column(
                  children: [
                    specialTextField(
                      label: 'First Name',
                      mainIcon: Iconsax.user,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    specialTextField(
                      label: 'Last Name',
                      mainIcon: Iconsax.user,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    specialTextField(
                      label: 'E-Mail',
                      mainIcon: Iconsax.direct,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    specialTextField(
                      label: 'Phone Number',
                      mainIcon: Iconsax.mobile,
                    ),
                    SizedBox(
                      height: 16,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              //sign up button

              specialButton(
                text: 'SignUp',
                function: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

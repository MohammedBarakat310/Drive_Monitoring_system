import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grad_project/components/SpecialButton.dart';
import 'package:grad_project/components/TextFormField.dart';
import 'package:grad_project/screens/HomeScreen.dart';
import 'package:iconsax/iconsax.dart';

class AddProfile extends StatefulWidget {
  const AddProfile(
      {super.key,
      required this.firstName,
      required this.lastName,
      required this.username,
      required this.email,
      required this.carNumber,
      required this.pass});

  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String carNumber;
  final String pass;

  @override
  State<AddProfile> createState() => _AddProfileState();
}

class _AddProfileState extends State<AddProfile> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  bool isLoading = false;

  final TextEditingController fname = TextEditingController();
  final TextEditingController lname = TextEditingController();
  final TextEditingController Email = TextEditingController();
  final TextEditingController phonenum = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> SignUp() async {
    setState(() {
      isLoading = true;
    });

    try {
      UserCredential user = await auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.pass,
      );

      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.user!.uid)
          .set({
        'firstName': widget.firstName,
        'lastName': widget.lastName,
        'username': widget.username,
        'email': widget.email,
        'carNumber': widget.carNumber,
        'emergencyContact': {
          'firstname': fname.text.trim(),
          'lastname': lname.text.trim(),
          'email': Email.text.trim(),
          'phone': phonenum.text.trim(),
        },
      });

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('password is weak try something stronger'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This E-mail is already in use'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    specialTextField(
                      label: 'First Name',
                      mainIcon: Iconsax.user,
                      controller: fname,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the first name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    specialTextField(
                      label: 'Last Name',
                      mainIcon: Iconsax.user,
                      controller: lname,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the last name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    specialTextField(
                      label: 'E-Mail',
                      mainIcon: Iconsax.direct,
                      controller: Email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the E-mail';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    specialTextField(
                      label: 'Phone Number',
                      mainIcon: Iconsax.mobile,
                      controller: phonenum,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
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
                text: isLoading ? 'Signing...' : 'SignUp',
                function: () {
                  if (_formKey.currentState!.validate()) {
                    SignUp();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

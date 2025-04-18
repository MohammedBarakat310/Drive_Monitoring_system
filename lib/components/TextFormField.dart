import 'package:flutter/material.dart';

// ignore: must_be_immutable, camel_case_types
class specialTextField extends StatelessWidget {
  const specialTextField(
      {super.key,
      required this.label,
      required this.mainIcon,
      this.secondIcon,
      this.controller,
      this.validator,
      this.obscure});
  final String label;
  final String? Function(String?)? validator;
  final IconData mainIcon;
  final IconData? secondIcon;
  final TextEditingController? controller;
  final bool? obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obscure ?? false,
      validator: validator,
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(mainIcon),
        labelText: label,
        suffixIcon: secondIcon != null ? Icon(secondIcon) : null,
        labelStyle: const TextStyle(
          color: Colors.black,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(8),
          ),
          borderSide: BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );
  }
}

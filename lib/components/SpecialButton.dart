import 'package:flutter/material.dart';

// ignore: must_be_immutable
class specialButton extends StatelessWidget {
  specialButton({super.key, required this.function, required this.text});
  final VoidCallback? function;
  final String text;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: function,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black.withOpacity(.8),
          ),
        ),
      ),
    );
  }
}

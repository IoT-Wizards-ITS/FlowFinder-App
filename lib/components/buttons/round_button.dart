// create button with rounded corners, with custom color and text

import 'package:flutter/material.dart';

class RoundButton extends StatelessWidget {
  const RoundButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.color = Colors.blue,
  }) : super(key: key);

  final VoidCallback onPressed;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
        backgroundColor: MaterialStateProperty.all<Color>(color),
      ),
      child: Text(text),
    );
  }
}
import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  const RoundedButton({
    Key? key,
    required this.buttonText,
    required this.onpressed,
  }) : super(key: key);

  final String buttonText;
  final VoidCallback onpressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.yellow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextButton(
        onPressed: onpressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            buttonText,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

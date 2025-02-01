import 'package:flutter/material.dart';
import 'package:whatsapppp/common/utils/color.dart';

// ignore: must_be_immutable
class CustomButton extends StatelessWidget {
  late final String text;
  void Function()? onPressed;

  CustomButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text(
        text,
        style: TextStyle(color: blackColor),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: tabColor,
        minimumSize: Size(double.infinity, 50),
      ),
    );
  }
}

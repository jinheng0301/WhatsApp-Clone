import 'package:flutter/material.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    // going to use loader everywhere in the app
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}
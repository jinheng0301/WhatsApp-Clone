import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectContactScreens extends ConsumerWidget {
  static const String routeName = '/select-contact';
  const SelectContactScreens({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Contact'),
      ),
    );
  }
}
